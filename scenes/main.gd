extends Node3D


func p(poi, foi, site, customer):
	return {
		"poi": poi,
		"foi": foi,
		"site": site,
		"customer": customer
	}

var progressions = [
	p(null, null, "instagram", preload("res://scenes/npcs/jim/jim.tscn")),
	p("jim", null, "facebook", preload("res://scenes/npcs/weaboo/weaboo.tscn")),
	p(null, "sunflower", "deviantart", preload("res://scenes/npcs/lucio/lucio.tscn"))
]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Global.mode == "market":
		if progressions.size() == 0:
			Global.mode = "sell"
	
	if Global.mode == "sell":
		if not get_children().any(func(c): return c is Customer):
			Global.mode = "end"
			end_game()

func equal(a: String, b: String):
	return a.nocasecmp_to(b) == 0

var fadeout = preload("res://scenes/util/fadeout.tscn")
var credits = preload("res://scenes/credits.tscn")

func end_game():
	add_child(fadeout.instantiate())
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_packed(credits)
	

func _on_player_photo_taken(texture: Texture, poi: Customer, foi: Flower, site: String, everything):
	if not is_instance_valid(poi) and not is_instance_valid(foi):
		# If photo has no interests, don't check progressions
		pass
	else:
		for prog in progressions:
			if not prog.poi and not prog.foi:
				# hack to allow tutorial photo
				init_customer(prog, texture)
				break
			# progression does not need a person or person matches progression
			if not prog.poi or (prog.poi and is_instance_valid(poi) and equal(poi.full_name, prog.poi)):
				# progression does not need a flower or flower matches progression
				if not prog.foi or (prog.foi and is_instance_valid(foi) and equal(foi.full_name, prog.foi)):
					# website is correct
					if equal(site, prog.site):
						init_customer(prog, texture)
						break

func init_customer(prog, texture):
	var unlocked_customer = prog.customer.instantiate()
	unlocked_customer.my_photo = texture
	# TODO
	unlocked_customer.position = $StoreExit.position
	add_child(unlocked_customer)
	progressions.erase(prog)
