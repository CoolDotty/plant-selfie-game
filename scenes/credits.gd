extends Node2D


var slide = preload("res://scenes/slide.tscn")
var cc = preload("res://scenes/credits_customer.tscn")

var window_width = 1152

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.stop_sound()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Add player to final head count
	var player = preload("res://scenes/customer/customer.tscn").instantiate()
	player.front_sprite = preload("res://assets/npc_bodies/player_front.png")
	player.my_photo = the_end
	Global.final_customers.push_back(player)
	animate()

var the_end = preload("res://assets/theend.png")

func animate():
	var size: float = Global.final_customers.size()
	var width: float = 1152.0 / 2
	var unit: float = width / size
	
	
	await get_tree().create_timer(5).timeout
	for i in Global.final_customers.size():
		var c = Global.final_customers[i]
		# slide
		var s: Slide = slide.instantiate()
		s.pic = c.my_photo
		if c.full_name != "Customer":
			s.message = c.full_name + " liked this post"
		else:
			s.message = "Thanks for playing!"
		s.customer = c.front_sprite
		if is_instance_valid(c.get_node("hand").get_child(0)):
			s.plant = c.get_node("hand").get_child(0).front_sprite
		s.z_index = i
		add_child(s)
		
		# customer slide in
		var cus = cc.instantiate()
		if i % 2 == 1:
			cus.target_pos = Vector2(unit * (size - 1 - floor(i / 2)), 622) + Vector2(100, 0)
		else:
			cus.target_pos = Vector2(unit * floor(i / 2), 622) + Vector2(100, 0)
		cus.z_index = 99 + i
		if i % 2 == 1:
			cus.position = $CustomerLeft.position
		else:
			cus.position = $CustomerRight.position
		cus.customer = c.front_sprite
		if is_instance_valid(c.get_node("hand").get_child(0)):
			cus.flower = c.get_node("hand").get_child(0).front_sprite
		add_child(cus)
		
		await get_tree().create_timer(6).timeout


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
