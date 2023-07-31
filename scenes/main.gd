extends Node3D


func p(poi, foi, site, customer):
	return {
		"poi": poi,
		"foi": foi,
		"site": site,
		"customer": customer
	}


# facebook, deviantart, instagram, reddit
var progressions = [
	p(null, null, "", preload("res://scenes/npcs/jim/jim.tscn")),
	p(null, "Mushroom", "facebook", preload("res://scenes/npcs/weaboo/weaboo.tscn")),
	p(null, "Chrysanthemum", "facebook", preload("res://scenes/npcs/omegaboomer/omegaboomer.tscn")),
	p(null, "Rose", "deviantart", preload("res://scenes/npcs/animeartist/animeartist.tscn")),
	p("Cassidy", null, "reddit", preload("res://scenes/npcs/mrbeast/mrbeast.tscn")),
	p("Jonathan", null, "deviantart", preload("res://scenes/npcs/lucio/lucio.tscn")),
	p(null, "Lotus", "facebook", preload("res://scenes/npcs/streamer/streamer.tscn")),
	p("Mr Yeast", "Sunflower", "instagram", preload("res://scenes/npcs/billygates/billygates.tscn"))
]
# preload("res://scenes/npcs/lucio/lucio.tscn"))


# Called when the node enters the scene tree for the first time.
func _ready():
	_start_game()

func _start_game():
	await get_tree().create_timer(5).timeout
	$player.do_phonecall($player.tutorial_call)
	await get_tree().create_timer(5).timeout
	$Shoppin4Plantz.finished.connect(func(): [$Shoppin4Plantz, $shop_song].pick_random().play())
	$shop_song.finished.connect(func(): [$Shoppin4Plantz, $shop_song].pick_random().play())
	DialogueManager.dialogue_ended.connect(
		func(a):
			[$Shoppin4Plantz, $shop_song].pick_random().play()
	, CONNECT_ONE_SHOT)

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
	$player.do_phonecall($player.finish_call)
	DialogueManager.dialogue_ended.connect(
		func(d):
			add_child(fadeout.instantiate())
			await get_tree().create_timer(5).timeout
			get_tree().change_scene_to_packed(credits)
	)
	

func _on_player_photo_taken(texture: Texture, poi: Customer, foi: Flower, site: String, everything):
	# Wait for photo post to finish spinning
	await get_tree().create_timer(4).timeout
	for prog in progressions:
		if not prog.poi and not prog.foi:
			init_customer(prog, texture)
			return
		# progression does not need a person or person matches progression
		if not prog.poi or (prog.poi and is_instance_valid(poi) and equal(poi.full_name, prog.poi)):
			# progression does not need a flower or flower matches progression
			if not prog.foi or (prog.foi and is_instance_valid(foi) and equal(foi.full_name, prog.foi)):
				# website is correct
				if equal(site, prog.site):
					init_customer(prog, texture)
					return
	# mundane photo
	$LikesNotification/Label.text = "%s people liked your post" % randi_range(2, 9)
	$LikesNotification.go()
	Global.play_sound("like")

func init_customer(prog, texture):
	progressions.erase(prog)
	var unlocked_customer = prog.customer.instantiate()
	unlocked_customer.my_photo = texture
	# hack to allow no requirement photos
	$LikesNotification/Label.text = "%s people liked your post" % randi_range(100, 500)
	$LikesNotification.go()
	Global.play_sound("like")
	# 3
	await get_tree().create_timer(3).timeout
	Global.play_sound("comment")
	$CommentNotification/Label.text = "%s followed you!" % unlocked_customer.full_name
	$CommentNotification.go()
	# 5
	await get_tree().create_timer(5).timeout
	unlocked_customer.position = $StoreExit.position
	$StoreExit/DoorChime.play()
	add_child(unlocked_customer)


func _on_player_picked_up(name):
	if name:
		$CurrentPlant.go()
		$CurrentPlant/Label.text = name
