class_name Player extends CharacterBody3D


signal photo_taken(texture: Texture, poi: Customer, foi: Flower, site: String, everything)

signal picked_up(name: String)


@export_category("Player")
@export_range(1, 35, 1) var speed: float = 5 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var camera: Camera3D = $Camera
@onready var phone_ui = $PhoneUI
@onready var subview = $PhoneUI/CameraAppView/SubViewportContainer/SubViewport
@onready var phone_camera = $PhoneUI/CameraAppView/SubViewportContainer/SubViewport/phone_camera

@export var move_freeze := false
@export var phone_freeze := false

@export var phone_on := false

@export var tutorial_call: DialogueResource
@export var sell_call: DialogueResource

@onready var CameraAppView = $PhoneUI/CameraAppView
@onready var GallaryAppView = $PhoneUI/GallaryAppView
@onready var ShareAppView = $PhoneUI/ShareAppView

func _ready() -> void:
	capture_mouse()
	
	DialogueManager.got_dialogue.connect(on_dialogue_start)
	DialogueManager.dialogue_ended.connect(on_dialogue_end)
	
	CameraAppView.visible = false
	GallaryAppView.visible = false
	ShareAppView.visible = false
	
	
	Global.mode_changed.connect(
		func(mode):
			if mode == "sell":
				await get_tree().create_timer(5).timeout
				do_phonecall(sell_call)
	, CONNECT_ONE_SHOT)

var is_talking = false

func on_dialogue_start(_line):
	release_mouse()
	if not phonecall:
		phone_freeze = true
	is_talking = true

func on_dialogue_end(_res):
	capture_mouse()
	phone_freeze = false
	is_talking = false
	last_chat_ended_at = Time.get_ticks_msec()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("exit"): release_mouse()
	if move_freeze: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed("jump"): jumping = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: capture_mouse()


func _on_facebook_pressed(): 
	Global.play_sound("ui_click")
	selected_social = "facebook"
func _on_deviant_art_pressed(): 
	Global.play_sound("ui_click")
	selected_social = "deviantart"
func _on_instagram_pressed(): 
	Global.play_sound("ui_click")
	selected_social = "instagram"
func _on_reddit_pressed(): 
	Global.play_sound("ui_click")
	selected_social = "reddit"

var selected_social = "facebook"
var current_photo = null

var last_chat_ended_at = 0

var last_time_posted: float = 0

func _process(delta):
	$hand.position = Vector3(0, 0.33, -0.66).rotated(Vector3(0, 1, 0), camera.rotation.y)
	
	if phonecall:
		$PhoneUI/PhonecallUi.scale = $PhoneUI/PhonecallUi.scale.lerp(Vector2(1, 1), delta * 20)
		$PhoneUI/PhonecallUi/calltime.text = Time.get_time_string_from_unix_time(Time.get_unix_time_from_system() - call_start)
	else:
		$PhoneUI/PhonecallUi.scale = $PhoneUI/PhonecallUi.scale.lerp(Vector2(1, 0), delta * 20)
	
	$PhoneUI/PostingUi/Spinner.rotation_degrees -= 360 * delta
	if Time.get_unix_time_from_system() > last_time_posted + 3.0:
		$PhoneUI/PostingUi.scale = $PhoneUI/PostingUi.scale.lerp(Vector2(1, 0), delta * 20)
	else:
		$PhoneUI/PostingUi.scale = $PhoneUI/PostingUi.scale.lerp(Vector2(1, 1), delta * 20)

func _physics_process(delta: float) -> void:
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()
	
	if is_instance_valid(phone_camera):
		phone_camera.global_transform = $Camera.global_transform
		phone_camera.fov = $Camera.fov * 3 / 4
	
	if Input.is_action_just_pressed("toggle_phone") and not phonecall:
		if phone_on:
			turn_off_phone()
		else:
			turn_on_phone()
	
	if phone_freeze or not $PhoneUI.visible:
		phone_on = false
		CameraAppView.visible = false
		GallaryAppView.visible = false
		ShareAppView.visible = false
	
	var phone_target: float = 0.0 if phone_on else 135.0
	phone_ui.rotation_degrees = lerp(phone_ui.rotation_degrees, phone_target, 0.1)
	
	if Input.is_action_just_pressed("take_photo"):
		if phone_on:
			if CameraAppView.visible:
				if phonecall:
					return
				if Time.get_ticks_msec() - last_chat_ended_at < 250:
					return
				current_photo = take_photo()
				Global.play_sound("photo")
				CameraAppView.visible = false
				$PhoneUI/GallaryAppView/Flash.modulate.a = 1.0
				GallaryAppView.visible = true
		else:
			# Hack to not instantly talk again after clicking goodbye chat option
			if Time.get_ticks_msec() - last_chat_ended_at > 250:
				attempt_to_interact()
	
	if GallaryAppView.visible:
		GallaryAppView.get_node("PicturePreview").texture = current_photo.photo
		$PhoneUI/GallaryAppView/Flash.modulate.a = max($PhoneUI/GallaryAppView/Flash.modulate.a - 1.0 / 60, 0.0)
		release_mouse()
	
	if ShareAppView.visible:
		match selected_social:
			"facebook":
				$PhoneUI/ShareAppView/Control/SocialBG.texture = preload("res://assets/social_sites/facebookbg.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.texture = preload("res://assets/social_sites/facebookfg.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.modulate.a = 1.0
				$PhoneUI/ShareAppView/Control/ExtraFG.texture = preload("res://assets/social_sites/facebookfgbonus.png")
			"deviantart":
				$PhoneUI/ShareAppView/Control/SocialBG.texture = preload("res://assets/social_sites/artstagram.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.texture = null
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.modulate.a = 1.0
				$PhoneUI/ShareAppView/Control/ExtraFG.texture = null
			"reddit":
				$PhoneUI/ShareAppView/Control/SocialBG.texture = preload("res://assets/social_sites/xmemesbg.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.texture = preload("res://assets/social_sites/xmemesfg.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.modulate.a = 1.0
				$PhoneUI/ShareAppView/Control/ExtraFG.texture = null
			"instagram":
				$PhoneUI/ShareAppView/Control/SocialBG.texture = preload("res://assets/social_sites/bandsbg.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.texture = preload("res://assets/social_sites/bandsfg.png")
				$PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport/SocialOverlay.modulate.a = 0.6
				$PhoneUI/ShareAppView/Control/ExtraFG.texture = null

func turn_off_phone():
	current_photo = null
	Global.play_sound("phone_off")
	phone_on = false
	CameraAppView.visible = false
	GallaryAppView.visible = false
	ShareAppView.visible = false
	capture_mouse()

func turn_on_phone():
	drop()
	phone_on = true
	Global.play_sound("phone_on")
	CameraAppView.visible = true
	GallaryAppView.visible = false
	ShareAppView.visible = false

func _on_trash_pressed(): 
	Global.play_sound("ui_click")
	_on_reject_picture_pressed()

func _on_post_pressed():
	Global.play_sound("post")
	# Get photo with overlay
	var img = $PhoneUI/ShareAppView/Control/SubViewportContainer/SubViewport.get_texture().get_image()
	var photo = ImageTexture.create_from_image(img)
	photo_taken.emit(photo, current_photo.poi, current_photo.foi, selected_social, current_photo.interests)
	last_time_posted = Time.get_unix_time_from_system()
	CameraAppView.visible = true
	GallaryAppView.visible = false
	ShareAppView.visible = false
	capture_mouse()


func _on_reject_picture_pressed():
	Global.play_sound("ui_click")
	CameraAppView.visible = true
	GallaryAppView.visible = false
	ShareAppView.visible = false
	capture_mouse()


func _on_accept_picture_pressed():
	Global.play_sound("ui_click")
	CameraAppView.visible = false
	GallaryAppView.visible = false
	ShareAppView.visible = true
	ShareAppView.get_node("Control/SubViewportContainer/SubViewport/Pic").texture = current_photo.photo
	selected_social = "facebook"


func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		capture_mouse()


const max_distance_to_talk = 2.0
func attempt_to_interact():
	
	var bodies_in_photo: Array[Node3D] = $Camera/SnapshotHitbox.get_overlapping_bodies()
	var thing_of_interest
	for interest in bodies_in_photo:
		if not (interest is Customer or interest is Flower):
			continue
		if not is_instance_valid(thing_of_interest):
			if interest.global_position.distance_to(global_position) < max_distance_to_talk:
				thing_of_interest = interest
		else:
			if thing_of_interest.global_position.distance_to(global_position) > interest.global_position.distance_to(global_position):
				thing_of_interest = interest
	
	if is_instance_valid(thing_of_interest):
		if thing_of_interest is Customer:
			if not is_talking and not phone_on:
				if Global.mode == "market":
					if $hand.get_child_count() == 0:
						thing_of_interest.talk(self)
					else:
						drop()
				if Global.mode == "sell":
					if $hand.get_child_count() == 0:
						thing_of_interest.talk(self)
					else:
						sell(thing_of_interest)
		if thing_of_interest is Flower:
			if not is_talking and not phone_on:
				if $hand.get_child_count() > 0:
					drop()
				else:
					pickup(thing_of_interest)
	else:
		drop()


func pickup(thing_of_interest, forced=false):
	if not forced and Time.get_ticks_msec() - last_chat_ended_at < 250:
		return
	Global.play_sound("pot_pick")
	thing_of_interest.get_parent().remove_child(thing_of_interest)
	thing_of_interest.position = Vector3.ZERO
	thing_of_interest.no_collide = true
	await get_tree().physics_frame
	$hand.add_child(thing_of_interest)
	picked_up.emit(thing_of_interest.full_name)


func drop():
	if $hand.get_child_count() == 0:
		return
	Global.play_sound("pot_drop")
	last_chat_ended_at = Time.get_ticks_msec()
	var thing_held = $hand.get_child(0)
	var pos = thing_held.global_position
	$hand.remove_child(thing_held)
	thing_held.no_collide = false
	await get_tree().physics_frame
	thing_held.position = pos
	thing_held.velocity = velocity + Vector3(0, 3, 0)
	owner.get_parent().add_child(thing_held)
	picked_up.emit(null)

func sell(to: Customer):
	if $hand.get_child_count() == 0:
		return
	last_chat_ended_at = Time.get_ticks_msec()
	var thing_held = $hand.get_child(0)
	$hand.remove_child(thing_held)
	await get_tree().physics_frame
	var didsell = to.sell(thing_held)
	if not didsell:
		$hand.add_child(thing_held)

func take_photo():
	# Retrieve the captured image.
	var img = subview.get_texture().get_image()
	var photo = ImageTexture.create_from_image(img)
	
	var bodies_in_photo: Array[Node3D] = $Camera/SnapshotHitbox.get_overlapping_bodies()
	var interests_in_photo = bodies_in_photo.filter(
		func(b):
			if b == self:
				return false
			if b is Customer:
				return true
			if b is Flower:
				return true
			return false
	)
	
	var person_of_interest
	var flower_of_interest
	
	for interest in interests_in_photo:
		if interest is Customer:
			if not is_instance_valid(person_of_interest):
				person_of_interest = interest
			else:
				if person_of_interest.global_position.distance_to(global_position) > interest.global_position.distance_to(global_position):
					person_of_interest = interest
		if interest is Flower:
			if not is_instance_valid(flower_of_interest):
				flower_of_interest = interest
			else:
				if flower_of_interest.global_position.distance_to(global_position) > interest.global_position.distance_to(global_position):
					flower_of_interest = interest
	
	# Set the texture to the captured image node.
	return {
		"photo": photo,
		"poi": person_of_interest,
		"foi": flower_of_interest,
		"interests": interests_in_photo
	}

var phonecall = false
var call_start = 0

func do_phonecall(res: DialogueResource):
	while is_talking:
		await DialogueManager.dialogue_ended
		await get_tree().create_timer(2).timeout
	last_chat_ended_at = Time.get_ticks_msec() + 4000
	Global.play_sound("ringtone", 2)
	await get_tree().create_timer(2).timeout
	call_start = Time.get_unix_time_from_system()
	turn_on_phone()
	phonecall = true
	DialogueManager.dialogue_ended.connect(func(_a): phonecall = false, CONNECT_ONE_SHOT)
	DialogueManager.show_example_dialogue_balloon(res)


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	phone_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_freeze = false

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	phone_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	move_freeze = true

func _rotate_camera(sens_mod: float = 1.0) -> void:
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector("look_left","look_right","look_up","look_down")
	if joypad_dir.length() > 0:
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod)
		look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	if move_freeze: return Vector3.ZERO
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var _forward: Vector3 = camera.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel
