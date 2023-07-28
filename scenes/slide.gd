extends Node2D
class_name Slide

@export var pic: Texture
@export var message: String
@export var customer: Texture
@export var plant: Texture


var in_pos = Vector2(927, 312)
var in_rot = deg_to_rad(randf_range(-15, 15))


# Called when the node enters the scene tree for the first time.
func _ready():
	$picture.texture = pic
	$picture/Label.text = message
	animate()

var target_pos: Vector2
var target_rot: float

func animate():
	target_pos = in_pos
	target_rot = in_rot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(target_pos, 0.01)
	rotation = lerp_angle(rotation, target_rot, 0.01)
