@tool
extends CharacterBody3D
class_name Customer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var full_name: String = "Customer"
@export var front_sprite = preload("res://icon.svg")
@export var back_sprite = preload("res://icon.svg")
@export var dialogue: DialogueResource
@export var purchase_dialogue: DialogueResource

var looking_at: Node3D = null

@onready var navigation_agent = $NavigationAgent3D
var movement_speed: float = 2.0
var movement_target_position: Vector3 = Vector3(-3.0, 0.0, 2.0)

var my_photo: Texture

var exiting = false

func _path_random_pos():
	const r = 10
	set_movement_target(position + Vector3(
		randf_range(-r, r),
		0,
		randf_range(-r, r)
	))

func _ready():
	velocity = Vector3.ZERO
	
	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	# Now that the navigation map is no longer empty, set the movement target.
	_path_random_pos()

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func abort_movement():
	navigation_agent.set_target_position(position)

func _process(delta):
	if Engine.is_editor_hint():
		$Billboard.texture = front_sprite
		return
	if not navigation_agent.is_navigation_finished():
		$Billboard.animation.current_animation = "walking"
		$Billboard.animation.speed_scale = 2.0
	else:
		$Billboard.animation.current_animation = "vibing"
		$Billboard.animation.speed_scale = 1.0
	
	var z_vector = global_transform.basis.z
	var relative_pos = get_viewport().get_camera_3d().global_transform.origin - global_transform.origin
	var dot = z_vector.dot(relative_pos)
	if dot < 0:
		# in front
		$Billboard.texture = front_sprite
	else:
		# behind
		$Billboard.texture = back_sprite


const lose_attention_distance = 4.0


func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	velocity += Vector3(0, -gravity * delta, 0)
	if is_on_floor():
		velocity = Vector3.ZERO
	
	if not navigation_agent.is_navigation_finished():
		# is walking
		var current_agent_position: Vector3 = global_position
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		
		var new_velocity: Vector3 = next_path_position - current_agent_position
		new_velocity = new_velocity.normalized()
		new_velocity = new_velocity * movement_speed

		velocity += new_velocity
		rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z) + PI, 0.1)
	else:
		if exiting:
			# reach store exit
			(func():
				get_parent().remove_child(self)
				Global.final_customers.push_back(self)
			).call_deferred()
		# is idle
		if is_instance_valid(looking_at):
			# should we give up attention?
			if global_position.distance_to(looking_at.global_position) > lose_attention_distance:
				looking_at = null
				return
			# pay attention to player
			# hack to make the angle -2pi < angle < 2pi
			var target_angle = lerp_angle(0, looking_at.get_node("Camera").global_rotation.y + PI, 1.0)
			rotation.y = lerp_angle(rotation.y, target_angle, 0.1)
		else:
			# completely idle
			# chance to move around
			if randi() % 1000 == 1:
				_path_random_pos()
	
	move_and_slide()

func sell(plant: Node3D):
	if exiting: return
	$hand.add_child(plant)
	# play cha-ching
	# Leave store
	set_movement_target(get_parent().get_node("StoreExit").position)
	exiting = true

func talk(toWhom):
	if exiting: return
	abort_movement()
	looking_at = toWhom
	if Global.mode == "market":
		DialogueManager.show_example_dialogue_balloon(dialogue)
	if Global.mode == "sell":
		if purchase_dialogue:
			DialogueManager.show_example_dialogue_balloon(purchase_dialogue)
		else:
			DialogueManager.show_example_dialogue_balloon(dialogue)
	
	var target_angle = lerp_angle(0, looking_at.get_node("Camera").global_rotation.y + PI, 1.0)
	if abs(rotation.y - target_angle) > PI / 2:
		# Jump! Surprise!
		velocity = Vector3(0, 3, 0)
		move_and_slide()

