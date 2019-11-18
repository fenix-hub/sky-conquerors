extends CanvasLayer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var titlescreen=false

onready var TitleScreen = $TitleScreen
onready var Tutorial = $Tutorial
onready var Settings = $Settings
# Called when the node enters the scene tree for the first time.

func _ready():
	Tutorial.hide()
	Settings.hide()
	music.set_volume("Music",-10)
	music.music_stream(music.titlescreen)
	music.music_play()
	$AnimationPlayer.play("titlescreen")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name=="titlescreen":
		titlescreen=true

func _on_exit_pressed():
	if titlescreen==true:
		music.button_play()
		get_tree().quit()


func _on_credits_pressed():
	if titlescreen==true:
		music.button_play()
#		add_child(load(scene_loader.Credits).instance())
		

func _on_new_game_pressed():
	if titlescreen==true:
		music.button_play()
#		Transition.play_transition(scene_loader.Level)
		var scena = load(scene_loader.Level)
		get_tree().change_scene(scena.resource_path)

func _on_settings_pressed():
	if titlescreen==true:
		music.button_play()
		
		TitleScreen.hide()
		Settings.show()
		
#		add_child(load(scene_loader.Settings).instance())


func _on_controls_pressed():
	if titlescreen==true:
		music.button_play()
		
		TitleScreen.hide()
		Tutorial.show()
#		add_child(load(scene_loader.Controls).instance())


func _on_Audio_toggled(button_pressed):
	music.audio_player_off()


func _on_back_pressed():
	music.button_play()
	TitleScreen.show()
	Tutorial.hide()

func _on_audio_value_changed(value):
	music.set_volume("Music",value)


func _on_back_settings_pressed():
	music.button_play()
	TitleScreen.show()
	Settings.hide()
