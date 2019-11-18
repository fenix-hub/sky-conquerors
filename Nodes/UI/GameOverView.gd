extends Control

onready var ColorTween = $Tween

func _ready():
	hide()

func game_over(won : bool):
	get_parent().UnitDatas.hide()
	get_parent().UnitsDatas.hide()
	get_parent().StructureDatas.hide()
	get_parent().BuildingInstructions.hide()
	show()
	get_tree().paused = true
	$Label.clear()
	if won:
		$Label.append_bbcode("[center][wave freq=2][pulse color=#514985 freq=6.0 height=5.0]YOU WON[/pulse][/wave][/center]")
	else:
		$Label.append_bbcode("[center][wave freq=2][pulse color=#ea2351 freq=6.0 height=5.0]GAME OVER[/pulse][/wave][/center]")
	ColorTween.play("game_over")

func _on_restart_pressed():
	music.button_play()
	Transition.play_transition(scene_loader.Level)

func _on_title_screen_pressed():
	music.button_play()
	Transition.play_transition(scene_loader.TitleScreen)

func _on_quit_pressed():
	music.button_play()
	get_tree().quit()
