extends Node

signal mode_changed(mode)

# market, sell
var mode = "market" :
	set(value):
		if mode != value:
			mode_changed.emit(value)
		mode = value

var final_customers: Array[Customer] = []

var current_bloop: String = "bloop1"

var snd = {}

func _ready():
	register_loop(preload("res://assets/sounds/quiet-spring-woodland-ambience.ogg"))
	
	register_sound("ringtone", preload("res://assets/sounds/cute-ringtone vibritherabjit123.ogg"))
	register_sound("ui_click", preload("res://assets/sounds/click_002.ogg"))
	register_sound("photo", preload("res://assets/sounds/photo.ogg"))
	register_sound("like", preload("res://assets/sounds/Rise01.ogg"))
	register_sound("comment", preload("res://assets/sounds/Rise07.ogg"))
	register_sound("phone_off", preload("res://assets/sounds/phone_off.ogg"))
	register_sound("phone_on", preload("res://assets/sounds/phone_on.ogg"))
	register_sound("purchase", preload("res://assets/sounds/purchase.ogg"))
	register_sound("pot_pick", preload("res://assets/sounds/pot_pick.ogg"))
	register_sound("pot_place", preload("res://assets/sounds/pot_place.ogg"))
	register_sound("pot_drop", preload("res://assets/sounds/pot_drop.ogg"))
	register_sound("bloop1", preload("res://assets/sounds/bloop1.ogg"))
	register_sound("post", preload("res://assets/sounds/text-send.ogg"))
	register_sound("shoppin4plantz", preload("res://assets/sounds/Shoppin4plantz.ogg"))
	register_sound("doorchime", preload("res://assets/sounds/doorchime.ogg"))

func register_sound(name: String, sound: AudioStream):
	snd[name] = sound

func register_loop(sound: AudioStream):
	var a = AudioStreamPlayer.new()
	a.stream = sound
	a.finished.connect(func(): a.play())
	a.volume_db = -10
	add_child(a)
	a.play()

func play_blip(name: String):
	var a = AudioStreamPlayer.new()
	a.stream = snd[name]
	a.finished.connect(func(): a.queue_free(), CONNECT_ONE_SHOT)
	a.pitch_scale = randf_range(0.5, 1.5)
	add_child(a)
	a.play()

func play_sound(name: String, timeout: float = -1):
	var a = AudioStreamPlayer.new()
	a.stream = snd[name]
	add_child(a)
	a.play()
	if timeout > 0:
		await get_tree().create_timer(timeout).timeout
		a.stop()
		a.queue_free()
	else:
		a.finished.connect(func(): a.queue_free(), CONNECT_ONE_SHOT)

func stop_sound():
	for c in get_children():
		if c is AudioStreamPlayer:
			c.stop()
			c.queue_free()
