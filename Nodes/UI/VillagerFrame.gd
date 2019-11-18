extends Node

func _ready():
	pass # Replace with function body.

func get_villager_texture(job : int):
	var image_name = job
	return (load("res://Resources/Imgs/villagers/villager_frames/"+str(job)+".png"))

func get_structure_texture(structure_name : String):
	return(load("res://Resources/Imgs/tile_frames/"+structure_name.to_lower()+".png"))

func get_item_texture(item_name : String):
	return(load("res://Resources/Imgs/fx/"+item_name+".png"))
