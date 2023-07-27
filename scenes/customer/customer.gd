@tool
extends CharacterBody3D
class_name Customer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var full_name: String = "Customer"
@export var front_sprite = preload("res://icon.svg")
@export var back_sprite = preload("res://icon.svg")
@export var dialogue: DialogueResource

var looking_at: Node3D = null

func _process(delta):
	if Engine.is_editor_hint():
		$Billboard.texture = front_sprite
		return
	$Billboard.animation.current_animation = "vibing"
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
	if is_instance_valid(looking_at):
		# should we give up attention?
		if global_position.distance_to(looking_at.global_position) > lose_attention_distance:
			looking_at = null
			rotation.y = 0 # DEBUG
			return
		# pay attention to player
		# hack to make the angle -2pi < angle < 2pi
		var target_angle = lerp_angle(0, looking_at.get_node("Camera").global_rotation.y + PI, 1.0)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.1)
	else:
		# idle stuff wander around
		pass
	
	velocity += Vector3(0, -gravity * delta, 0)
	if is_on_floor():
		velocity = Vector3.ZERO
	move_and_slide()


func talk(toWhom):
	assert(dialogue, "No dialogue !!!")
	looking_at = toWhom
	DialogueManager.show_example_dialogue_balloon(dialogue)
	
	var target_angle = lerp_angle(0, looking_at.get_node("Camera").global_rotation.y + PI, 1.0)
	if abs(rotation.y - target_angle) > PI / 2:
		# Jump! Surprise!
		velocity = Vector3(0, 3, 0)
		move_and_slide()

