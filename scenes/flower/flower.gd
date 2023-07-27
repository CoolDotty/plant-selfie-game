@tool
extends CharacterBody3D
class_name Flower

@export var full_name: String = "Flower"
@export var front_sprite = preload("res://icon.svg")

func _process(_delta):
	$Billboard.texture = front_sprite
	if Engine.is_editor_hint(): return
	$Billboard.animation.current_animation = "vibing"
	
	var target_rot = get_viewport().get_camera_3d().global_rotation.y
	rotation.y = target_rot

func _physics_process(delta):
	pass
