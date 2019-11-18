extends CanvasLayer

onready var Infos = $Control/Datas
onready var Faction = $Control/Datas/Faction/value
onready var Population = $Control/Datas/Population/value
onready var Resources = $Control/Datas/Resources/value

var current_infos : Control

func _ready():
	pass # Replace with function body.

func _process(delta):
	if current_infos != null and current_infos.is_visible() :
		current_infos.set_position(get_viewport().get_mouse_position() + Vector2(32,32))

func show_island_infos(infos : Array):
	Infos.show()
	Faction.set_text(infos[0])
	current_infos = Infos

func hide_island_infos():
	current_infos.hide()
	current_infos = null
