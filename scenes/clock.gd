extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var start = Time.get_unix_time_from_system()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Sun.rotation_degrees += 2 * delta
	var passed = Time.get_unix_time_from_system() - start
	$BG/Label.text = Time.get_time_string_from_unix_time(1688893200 + passed).substr(0, 5)
