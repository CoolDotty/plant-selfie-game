@tool
extends CharacterBody3D
class_name Flower

@export var full_name: String = "Flower"
@export var front_sprite = preload("res://icon.svg")
@export var no_collide := false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _process(_delta):
	$Billboard.texture = front_sprite
	if Engine.is_editor_hint(): return
	$Billboard.animation.current_animation = "vibing"
	
	if get_parent().get_parent() is Customer:
		rotation.y = 0
	else:
		if not is_instance_valid(get_viewport().get_camera_3d()): return
		var target_rot = get_viewport().get_camera_3d().global_rotation.y
		rotation.y = target_rot

func _physics_process(delta):
	$CollisionShape3D.disabled = no_collide
	if no_collide: return
	if Engine.is_editor_hint(): return
	velocity += Vector3(0, -gravity * delta, 0)
	velocity = velocity.move_toward(Vector3.ZERO, delta)
	move_and_slide()
