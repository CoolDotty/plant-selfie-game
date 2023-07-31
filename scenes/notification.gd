extends ColorRect


var start = 0

var pos_in: float = 50
var pos_out: float = -250

func go():
	start = Time.get_unix_time_from_system()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	if Time.get_unix_time_from_system() > start + 5:
		position.x = lerp(position.x, pos_out, 0.1)
	else:
		position.x = lerp(position.x, pos_in, 0.1)
	$Label.global_position = position
