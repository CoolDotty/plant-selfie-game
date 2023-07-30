@tool
extends Node2D


@export var customer: Texture
@export var flower: Texture
@export var target_pos: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	$Customer.texture = customer
	$Flower.texture = flower


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Customer.texture = customer
	$Flower.texture = flower
	
func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	position = position.lerp(target_pos, 0.025)
