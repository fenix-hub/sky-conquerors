extends CanvasLayer

onready var IslandDatas = $IslandDatas

onready var UnitDatas = $UnitDatas
onready var UnitsDatas = $UnitsDatas
onready var StructureDatas = $StructureDatas
onready var BuildingInstructions = $BuildingInstructions

onready var GameOverView = $GameOverView

onready var Options = $Options

var UnitButton = preload("res://Nodes/UI/GeneralButton.tscn")

func _ready():
	UnitDatas.hide()
	UnitsDatas.hide()
	StructureDatas.hide()
	BuildingInstructions.hide()
	Options.hide()

func _on_spawn_btn_pressed():
	pass # Replace with function body.

func show_unit_datas(unit : Villager):
	update_unit(unit)
	UnitDatas.show()
	UnitsDatas.hide()

func hide_unit_datas():
	UnitDatas.hide()

func update_unit(unit):
	var unit_datas = unit.get_datas()
	UnitDatas.UnitLife.max_value = (unit_datas.life_max)
	UnitDatas.UnitLife.set_value(unit_datas.life)
	UnitDatas.UnitLife.get_node("life_value").set_text(str(unit_datas.life)+"/"+str(unit_datas.life_max))
	
	UnitDatas.UnitName.set_text(unit_datas.name)
	UnitDatas.UnitAge.set_text(str(unit_datas.age))
	
	var job : String
	match unit_datas.job:
		0:
			job = "Villager"
		1:
			job = "Farmer"
		2:
			job = "Woodcutter"
		3:
			job = "Miner"
		4:
			job = "Builder"
		5:
			job = "Soldier"
	UnitDatas.UnitJob.set_text(job)
	
	UnitDatas.UnitItems.set_text(str(unit_datas.items))
	UnitDatas.UnitTexture.set_texture(VillagerTexture.get_villager_texture(unit_datas.job))
	
	if unit_datas.job == Villager.VILLAGER_JOBS.soldier:
		UnitDatas.UnitJobs.hide()
		UnitDatas.UnitActions.show()
	else:
		UnitDatas.UnitJobs.show()
		UnitDatas.UnitActions.hide()

func show_units_datas(units : Array):
	update_units(units)
	UnitsDatas.show()
	UnitDatas.hide()

func hide_units_datas():
	UnitsDatas.hide()

func update_units(units):
	UnitsDatas.UnitsLife.max_value = 0
	UnitsDatas.UnitsLife.value = 0
	for children in UnitsDatas.Units.get_children():
		children.queue_free()
	for unit in units:
		var unit_datas = unit.get_datas()
		UnitsDatas.Units.add_child(create_unit_button(unit))
		UnitsDatas.UnitsLife.max_value += (unit_datas.life_max)
		UnitsDatas.UnitsLife.value += (unit_datas.life)
		UnitsDatas.UnitsLife.get_node("life_value").set_text(str(UnitsDatas.UnitsLife.value)+"/"+str(UnitsDatas.UnitsLife.max_value))
	UnitsDatas.UnitsAmount.set_text(str(units.size()))

func update_population_datas(population : Dictionary):
	var population_infos : String
	population_infos += "Villagers: "+str(population.get("villagers"))+"\n"
	population_infos += "Farmers: "+str(population.get("farmers"))+"\n"
	population_infos += "Woodcutters: "+str(population.get("woodcutters"))+"\n"
	population_infos += "Miners: "+str(population.get("miners"))+"\n"
	population_infos += "Builders: "+str(population.get("builders"))+"\n"
	population_infos += "Soldiers: "+str(population.get("soldiers"))+"\n"
	set_population(population.total)
	set_population_max(population.max)
	IslandDatas.Population.set_tooltip(population_infos)

func create_unit_button(unit) -> GeneralButton:
	var unit_datas = unit.get_datas()
	var unit_button = UnitButton.instance()
	unit_button.unit = unit
	unit_button.set_normal_texture(VillagerTexture.get_villager_texture(unit_datas.job))
	unit_button.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	unit_button.get_node("GeneralButton").connect("pressed",unit,"set_selected",[false])
	unit_button.set_tooltip("Deselect this unit")
	return unit_button

func update_resources_datas(resources : Dictionary):
	set_wood(resources.wood)
	set_stone(resources.stone)
	set_food(resources.food)

func hide_structure_datas():
	StructureDatas.hide()

func show_structure_datas():
	StructureDatas.show()

func update_structure_datas(structure : Dictionary):
	StructureDatas.StructureName.set_text(structure.name)
	StructureDatas.StructureLife.max_value = structure.max
	StructureDatas.StructureLife.value = structure.value
	StructureDatas.StructureLife.get_node("life_value").set_text(str(structure.value)+"/"+str(structure.max))
	StructureDatas.StructureIcon.set_texture(VillagerTexture.get_structure_texture(structure.name))
	StructureDatas.StructureDescription.set_text(structure.description)
	
	if structure.type == 10:
		StructureDatas.StructureOption.show()
	else:
		StructureDatas.StructureOption.hide()

func game_over(won : bool):
	GameOverView.game_over(won)

func set_wood(amount : int):
	IslandDatas.wood.set_text(str(amount))

func set_stone(amount : int):
	IslandDatas.stone.set_text(str(amount))

func set_food(amount : int):
	IslandDatas.food.set_text(str(amount))

func set_population(amount : int):
	IslandDatas.population_total.set_text(str(amount))

func set_population_max(amount : int):
	IslandDatas.population_max.set_text(str(amount))

func open_options():
	Options.visible = not Options.visible
	get_tree().paused = Options.visible


func _on_back_settings_pressed():
	music.button_play()
	$Settings.hide()


func _on_audio_value_changed(value):
	music.set_volume("Music",value)
