extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var protectors = 0
var temp_protectors = 0
var soul_fragments = 0

var human_list = []

#player
var player_soul_fragments = 0
var HP = 5
var HP_MAX = 5
var speed = 160
var power = 1
var stamina = 3
var guardians_possessed = 0
var humans_possessed = 0

var data = {}

var emitting_particles = true
var audio = true
var music_level = 0
var sound_effects_level = 0
var buttons_level = 0
var master_level = 0

var save1 = "user://save1.sav"
var save2 = "user://save2.sav"
var save3 = "user://save3.sav"

var settings = "res://settings.sav"

var save = ""

var temp_save1 = false
var temp_save2 = false
var temp_save3 = false 

var luogo
var luogo_nome
var stage = 0
var set = {}
var incrementer
var wait_time = 30
var max_guardians = 1
var enemies_on_stage = 0

func _ready():
	_init_loads()
	load_datas()
	load_data_settings()
	_load_settings()
	pass
	

func set_speed(s):
	self.speed = s
	
func set_stamina(s):
	self.stamina = s
	
func set_power(p):
	self.power = p
	
func set_HP(hp):
	self.HP=hp
	
func set_HP_MAX(hp_max):
	self.HP_MAX=hp_max
	
func set_guardians_possessed(pp):
	self.guardians_possessed=pp
	
func set_player_soul_fragments(sf):
	self.player_soul_fragments=sf

func load_datas():
	data = {
		"player_power": power ,
		"player_HP": HP ,
		"player_HP_MAX": HP_MAX ,
		"player_stamina": stamina ,
		"player_speed": speed ,
		"player_soul_fragments": player_soul_fragments ,
		"player_guardians_possessed": guardians_possessed,
		"max_guardians": max_guardians,
		"player_humans_possessed": humans_possessed,
		"stage":stage,
		"wait_time":wait_time,
		"luogo": luogo
		}
		

func load_data_settings():
	
	set = {
		"vfx": emitting_particles,
		"music_level": music_level,
		"sound_effects_level": sound_effects_level,
		"buttons_level": buttons_level,
		"master_level": master_level,
		}

func _save_settings():
	load_data_settings()
	var file = File.new()
	file.open(settings, File.WRITE) 
	file.store_line(JSON.print(set))
	file.close()

func _load_settings():
	var file = File.new()
	if file.open(settings, File.READ) != OK:
		_save_settings()
		return
	var data_text = file.get_as_text()
	file.close()
	var datas = JSON.parse(data_text).result
	emitting_particles = datas["vfx"]
	music_level = datas["music_level"]
	sound_effects_level = datas["sound_effects_level"]
	buttons_level = datas["buttons_level"]
	master_level = datas["master_level"]
	music.set_volume("Master",master_level)
	music.set_volume("Button",buttons_level)
	music.set_volume("Effect",sound_effects_level)
	music.set_volume("Music",music_level)

func _save():
	load_datas()
	var file = File.new()
	file.open(save, File.WRITE) 
	
	# Save the dictionary as JSON (or whatever you want, JSON is convenient here because it's built-in)
	file.store_line(JSON.print(data))
	file.close()
	update_luogo_nome()
	

func _load():
	var file = File.new()
	if file.open(save, File.READ) != OK:
		print("no save")
		return
	var data_text = file.get_as_text()
	file.close()
	var datas = JSON.parse(data_text).result
	power = datas["player_power"]
	HP = datas["player_HP"]
	HP_MAX = datas["player_HP_MAX"]
	stamina = datas["player_stamina"]
	speed = datas["player_speed"]
	player_soul_fragments = datas["player_soul_fragments"]
	guardians_possessed = datas["player_guardians_possessed"]
	max_guardians = datas["max_guardians"]
	humans_possessed = datas["player_humans_possessed"]
	stage = datas["stage"]
	wait_time = datas["wait_time"]
	luogo = datas["luogo"]
	
	update_luogo_nome()
	
	print("save_state")
	
func _init_loads():
	var file = File.new()
	if file.open(save1, File.READ) != OK:
		temp_save1=false
	else:
		temp_save1=true
		
	if file.open(save2, File.READ) != OK:
		temp_save2=false
	else:
		temp_save2=true
		
	if file.open(save3, File.READ) != OK:
		temp_save3=false
	else:
		temp_save3=true
		
func update_luogo_nome():
	if luogo == scene_loader.Overworld:
		luogo_nome="Overworld"
	if luogo == scene_loader.Underworld:
		luogo_nome="Underworld"
