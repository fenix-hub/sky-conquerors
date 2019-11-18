extends Node2D

onready var IslandInfos = $IslandInfos
onready var IslandAnimation = $AnimationPlayer
onready var UI = get_parent().get_parent().get_node("UI")
onready var Camera = get_parent().get_parent().get_node("CustomCamera")

signal show_island_infos(infos)
signal hide_island_infos()
signal center_island(island_pos)

# infos = @type , @position
var infos : Array = [] setget set_infos,get_infos

# population = @unit_instance
var population : Array = [] setget set_population,get_population

var datas : Dictionary = {
	'resources':{
		'food':0,
		'stone':0,
		'wood':0
	},
	'population':{
		'total':0,
		'max':0,
		'villagers':0,
		'soldiers':0,
		'workers':{
			'builder':0,
			'farmer':0,
			'woodcutter':0,
			'miner':0,
		}
	}
}

func _ready():
	randomize()
	
	infos = ["type",self.global_position]
	
	connect("show_island_infos",UI,"show_island_infos")
	connect("hide_island_infos",UI,"hide_island_infos")
	connect("center_island",Camera,"move_to_position")
	
	IslandAnimation.set_speed_scale(rand_range(0.4,1))
	IslandInfos.hide()


func _on_Area_mouse_entered():
	emit_signal("show_island_infos",infos)

func _on_Area_mouse_exited():
	emit_signal("hide_island_infos")

func _on_Area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == 2:
			emit_signal("center_island",infos[1])

func set_infos(inf : Array) -> void:
	infos = inf

func get_infos() -> Array:
	return infos

func set_population(p : Array) -> void:
	population = p 

func get_population() -> Array:
	return population
