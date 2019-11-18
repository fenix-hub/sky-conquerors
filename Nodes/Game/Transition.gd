extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var next_scene : String

# Called when the node enters the scene tree for the first time.
func _ready():
	$Viewport/TransitionBackground.hide()
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func play_transition(scene):
	$Viewport/TransitionBackground.show()
	visible = true
	$Viewport/AnimationPlayer.play("transition")
	self.next_scene = scene
	
func _on_AnimationPlayer_animation_finished(anim_name):
	visible = false

func change_scene():
	music.fade_music()
	music.stop_music()
	var scene = scene_loader.load_scene(next_scene)
	var next = scene.get_path()
	get_tree().change_scene(next)
	

func start_process():
	get_tree().paused = false

func stop_process():
	get_tree().paused = true
