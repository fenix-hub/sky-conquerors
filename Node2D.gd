extends Node2D

func _ready():
	var vill = Villager.new("michale",20,200,Villager.VILLAGER_JOBS.builder)
	print(vill.get_datas())
