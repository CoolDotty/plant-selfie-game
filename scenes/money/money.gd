extends Node3D


var velocity = Vector3(randf_range(-0.01, 0.01), randf_range(0.065, 0.075), randf_range(0.001, 0.005))
var rot_speed = randf_range(-3, 4) * sign(velocity.x)


# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = velocity.rotated(Vector3(0, 1, 0), rotation.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_instance_valid(get_viewport().get_camera_3d()): return
	var target_rot = get_viewport().get_camera_3d().global_rotation.y
	rotation.y = target_rot

func _physics_process(delta):
	if position.y < -100:
		queue_free()
	velocity.y -= 0.002
	velocity.y = max(-0.01, velocity.y)
	position += velocity
	rotation_degrees.z += rot_speed
