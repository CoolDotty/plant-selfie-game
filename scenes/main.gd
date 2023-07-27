extends Node3D


func p(poi, foi, site, customer):
	return {
		"poi": poi,
		"foi": foi,
		"site": site,
		"customer": customer
	}

var progressions = [
	p("jim", "rose", "facebook", preload("res://scenes/npcs/weaboo/weaboo.tscn"))
]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func equal(a: String, b: String):
	return a.nocasecmp_to(b) == 0

func _on_player_photo_taken(texture: Texture, poi: Customer, foi: Flower, site: String, everything):
	if not is_instance_valid(poi) and not is_instance_valid(foi):
		# If photo has no interests, don't check progressions
		pass
	else:
		for prog in progressions:
			# progression does not need a person or person matches progression
			if not prog.poi or (prog.poi and is_instance_valid(poi) and equal(poi.full_name, prog.poi)):
				# progression does not need a flower or flower matches progression
				if not prog.foi or (prog.foi and is_instance_valid(foi) and equal(foi.full_name, prog.foi)):
					# website is correct
					if equal(site, prog.site):
						var unlocked_customer = prog.customer.instantiate()
						unlocked_customer.position.y = 1
						add_child(unlocked_customer)
						progressions.erase(prog)
						break
