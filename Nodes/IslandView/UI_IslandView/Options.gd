extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_restart_pressed():
	music.button_play()
	Transition.play_transition(scene_loader.Level)

func _on_title_screen_pressed():
	music.button_play()
	Transition.play_transition(scene_loader.TitleScreen)

func _on_quit_pressed():
	music.button_play()
	get_tree().quit()

func _on_Audio_toggled(button_pressed):
	music.audio_player_off()

func _on_continue_pressed():
	music.button_play()
	get_tree().paused = false
	hide()

func _on_controls_pressed():
	music.button_play()
	get_parent().get_node("Settings").show()


func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE and event.is_pressed():
			hide()
			get_tree().paused = false
