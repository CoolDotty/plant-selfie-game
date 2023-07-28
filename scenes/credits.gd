extends Node2D


var slide = preload("res://scenes/slide.tscn")

var window_width = 1152

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	animate()

var the_end = preload("res://assets/theend.png")

func animate():
	await get_tree().create_timer(5).timeout
	for i in Global.final_customers.size():
		var c = Global.final_customers[i]
		var s: Slide = slide.instantiate()
		s.pic = c.my_photo
		s.message = c.full_name + " liked this post"
		s.customer = c.front_sprite
		s.plant = c.get_node("hand").get_child(0).front_sprite
		s.z_index = i
		add_child(s)
		await get_tree().create_timer(6).timeout
	
	var s: Slide = slide.instantiate()
	s.pic = the_end
	s.z_index = Global.final_customers.size() + 1
	add_child(s)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
