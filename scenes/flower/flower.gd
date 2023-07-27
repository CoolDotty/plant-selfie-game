@tool
extends CharacterBody3D
class_name Flower

@export var full_name: String = "Flower"
@export var front_sprite = preload("res://icon.svg")

func _process(_delta):
	$Billboard.texture = front_sprite
	if Engine.is_editor_hint(): return
	$Billboard.animation.current_animation = "vibing"

func _physics_process(delta):
	pass
