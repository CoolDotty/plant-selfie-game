extends Sprite3D

@onready var animation: AnimationPlayer = $AnimationPlayer

func _process(_delta: float) -> void:
	# Get camera coordinates
	var cam : Camera3D = get_viewport().get_camera_3d()
	# TODO: Look at camera for billboard
