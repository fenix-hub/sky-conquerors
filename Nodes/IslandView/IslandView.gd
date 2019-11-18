extends Node

onready var UI = $UI
onready var Island = $Island
onready var Maps = $Island/Maps
onready var IslandMap = $Island/Maps/IslandMap/Map
onready var NavigationMap = $Island/Maps/IslandMap
onready var TilemapDatas = $TilemapDatas
onready var CustomCamera = $Island/CustomCamera
onready var FogOfWar = $FogOfWar

var rng = RandomNumberGenerator.new()

var VillagerUnit = preload("res://Nodes/Villager/Villager.tscn")

var units : Array = []
var multiple_selection : bool = false

var mouse_on_ui = false

signal unit_selected(unit)
signal units_selected(units)

# Called when the node enters the scene tree for the first time.
func _ready():
	music.set_volume("Music",0.0)
	music.music_stream(music.main_theme)
	music.music_play()
	
	randomize()
	
#	Island.resources.food = 200
#	Island.resources.wood = 300
#	Island.resources.stone = 300
#	Island.population.max = 20
	
	connect("unit_selected",UI,"show_unit_datas")
	connect("units_selected",UI,"show_units_datas")
	
	UI.set_population_max(Island.population.max)
	UI.update_population_datas(Island.population)
	UI.update_resources_datas(Island.resources)
	
	Island.generate_island(Vector2(),rng.randi_range(2,4),rng.randi_range(2,3),rng.randi_range(2,3))
	FogOfWar.remove_fog_area(Island.IslandMap.get_used_rect())
	
	generate_random_islands()

func generate_random_islands():
	var island_position : Vector2
	var island_size : int
	var populated : bool
	var is_populated : int = 0
	#down
	island_position = Vector2(12,10)
	island_size = rng.randi_range(3,5)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,rng.randf_range(2,4),randi()%2,populated,island_size*2)
	
	#left
	island_position = Vector2(-8,11)
	island_size = rng.randi_range(3,4)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,randi()%3+1,randi()%3+1,populated,island_size*2)
	
	#right
	island_position = Vector2(10,-10)
	island_size = rng.randi_range(3,7)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,rng.randi_range(2,5),rng.randi_range(2,5),populated,island_size*2)
	
	# top right
	island_position = Vector2(-3,-20)
	island_size = rng.randi_range(3,7)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,randi()%3+1,randi()%2,populated,island_size*2)
	
	#top left
	island_position = Vector2(-17,2)
	island_size = rng.randi_range(3,7)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,rng.randi_range(2,4),rng.randi_range(2,4),populated,island_size)
	
	#bottom left
	island_position = Vector2(2,18)
	island_size = rng.randi_range(4,7)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,rng.randi_range(5,9),rng.randi_range(5,9),populated,island_size)
	
	#bottom right
	island_position = Vector2(18,2)
	island_size = rng.randi_range(3,5)
	populated = bool(randi()%2)
	is_populated+=int(populated)
	Island.generate_other_island(island_position,island_size,randi()%2,rng.randi_range(5,9),populated,island_size*2)
	
	#up
	island_position = Vector2(-13,-11)
	island_size = rng.randi_range(3,7)
	if is_populated > 0:
		populated = bool(randi()%2)
	else:
		populated = true
	Island.generate_other_island(island_position,island_size,rng.randi_range(1,3),rng.randi_range(1,3),populated,island_size*2)

func _process(delta):
	if Input.is_action_just_pressed("shift"):
		if not multiple_selection:
			multiple_selection = true
	if Input.is_action_just_released("shift"):
		if multiple_selection:
			multiple_selection = false
			if units.size() > 1:
				emit_signal("units_selected",units)

func select_unit(unit : Node2D):
	if not multiple_selection:
		deselect_all_units()
	
	if not units.has(unit):
		units.append(unit)
	
	if units.size() < 2:
		emit_signal("unit_selected",unit)

func deselect_unit(unit : Node2D):
	if units.has(unit):
		units.erase(unit)
	if units.size() == 1:
		emit_signal("unit_selected",units[0])
	elif units.size() < 1:
		UI.hide_unit_datas()
	elif units.size() > 1:
		emit_signal("units_selected",units)

func set_unit_destination(destination : Vector2):
	if units.size():
		for unit in units:
			unit.move_to(destination)
			unit.stop_working()

func deselect_all_units() :
	if units.size() == 1:
		UI.hide_unit_datas()
	
	if units.size() > 1:
		UI.hide_units_datas()
	
	while units.size() > 0:
		units[0].set_selected(false)

func select_in_area(start_point,end_point):
	var area = [
	Vector2(min(start_point.x,end_point.x),min(start_point.y,end_point.y)),
	Vector2(max(start_point.x,end_point.x),max(start_point.y,end_point.y))
	]
	
	multiple_selection = true
	
	
	for villager in get_tree().get_nodes_in_group("villagers"):
		if villager.position.x > area[0].x and villager.position.x < area[1].x:
			if villager.position.y > area[0].y and villager.position.y < area[1].y:
				villager.set_selected(true)
	
	if units.size() > 1:
		emit_signal("units_selected",units)
	
	multiple_selection = false

func get_units() -> int:
	return units.size()

# ----------- manage enemies

func select_enemy(enemy):
	pass

func deselect_enemy(enemy):
	pass

# --------------- villagers

func villager_dead(villager):
	units.erase(villager)
	villager.remove_from_group("villagers")
	
	UI.hide_unit_datas()
	
	if get_tree().get_nodes_in_group("villagers").size()  < 1:
		UI.game_over(false)

func enemy_dead(enemy):
	enemy.remove_from_group("enemies")
	if get_tree().get_nodes_in_group("enemies").size()  < 1:
		UI.game_over(true)

#func spawn_enemy(from_pos):
#	var enemy = VillagerEnemy.instance()
#	enemy.set_position(Island.get_random_position_from(from_pos))
#	Maps.add_child(enemy)
#	enemy.create(enemy.VILLAGER_JOBS.soldier, self , NavigationMap )
	
#	Island.population.villagers += 1
#	Island.population.total += 1
#	UI.update_population_datas(Island.population)

func spawn_villager():
	var villager = VillagerUnit.instance()
	villager.set_position(Island.get_random_position())
	Maps.add_child(villager)
	villager.create(villager.VILLAGER_JOBS.villager, self , NavigationMap )
	
	Island.population.villagers += 1
	Island.population.total += 1
	UI.update_population_datas(Island.population)

func _on_villager_pressed():
	music.button_play()
	if Island.population.total < Island.population.max and Island.resources.food >= Island.prices.villager.food:
		spawn_villager()
		
		Island.resources.food-=Island.prices.villager.food
		
		UI.update_resources_datas(Island.resources)

func _on_soldier_pressed():
	music.button_play()
	if Island.population.total < Island.population.max and Island.resources.food >= Island.prices.soldier.food:
		var villager = VillagerUnit.instance()
		villager.set_position(Island.get_random_position())
		Maps.add_child(villager)
		villager.create(villager.VILLAGER_JOBS.soldier, self , NavigationMap )
		
		Island.population.soldiers += 1
		Island.population.total += 1
		UI.update_population_datas(Island.population)
		Island.resources.food-=Island.prices.soldier.food
		UI.update_resources_datas(Island.resources)

# --------------------------------

func show_structure_status(structure):
	TilemapDatas.show_structure_status(structure)

# -------- resources

func set_villager_job(job : int , structure : Dictionary):
	for unit in units:
		if unit.villager_job!=Villager.VILLAGER_JOBS.soldier:
			unit.remove_job()
			unit.set_job(job)
			match job:
				Villager.VILLAGER_JOBS.villager:
					Island.population.villagers+=1
				Villager.VILLAGER_JOBS.farmer:
					Island.population.farmers+=1
				Villager.VILLAGER_JOBS.woodcutter:
					Island.population.woodcutters+=1
				Villager.VILLAGER_JOBS.miner:
					Island.population.miners+=1
				Villager.VILLAGER_JOBS.builder:
					Island.population.builders+=1
				Villager.VILLAGER_JOBS.soldier:
					Island.population.soldiers+=1
		
			unit.add_job_position(structure)
	
	UI.update_population_datas(Island.population)
	
	deselect_all_units()

func update_villager_ui(villager : Villager):
	UI.update_unit(villager)
	UI.update_population_datas(Island.population)

func get_resource_from(villager : Villager , amount : int):
	var villager_job = villager.villager_job
	var working_on
	if villager.structure_to_work.size() > 0:
		working_on = villager.structure_to_work
		#UI.update_structure_datas(villager.structure_to_work[0])
	else:
		return
	
	match villager_job:
		Villager.VILLAGER_JOBS.woodcutter: # wood
			if working_on.value > 0:
				working_on.value -= amount
				var forest_idx = Island.forests_list.find(working_on)
				Island.forests_list[forest_idx] = working_on
				villager.add_item(villager_job,amount)
				Island.resources.wood+=amount
				UI.set_wood(Island.resources.wood)
			else:
				Island.destroy_structure(working_on)
				villager.remove_job_position(working_on)
				
		Villager.VILLAGER_JOBS.miner: # stone
			if working_on.value > 0:
				working_on.value -= amount
				var mine_idx = Island.mines_list.find(working_on)
				Island.mines_list[mine_idx] = working_on
				villager.add_item(villager_job,amount)
				Island.resources.stone+=amount
				UI.set_stone(Island.resources.stone)
			else:
				Island.destroy_structure(working_on)
				villager.remove_job_position(working_on)
				
		Villager.VILLAGER_JOBS.builder: # buiding structures
			if working_on.value < working_on.max:
				working_on.value += amount
				var structure_idx = Island.buildings_list.find(working_on)
				Island.buildings_list[structure_idx] = working_on
				villager.add_item(villager_job,amount)
			else:
				Island.destroy_structure(working_on)
				villager.remove_job_position(working_on)
		
		Villager.VILLAGER_JOBS.farmer: #food
			if working_on.value > 0:
				Island.resources.food+=amount
				UI.set_food(Island.resources.food)

func _on_spawn_btn_pressed():
	music.button_play()
	spawn_villager()

func _input(event):
	# ------- reload
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE and event.is_pressed():
			UI.open_options()
#			Island.clear_maps()
#			for villager in get_tree().get_nodes_in_group("villagers"):
#				villager.queue_free()
#			Island.generate_island(Vector2(randi() % 6 + 2, randi() % 6 + 2),1,2)

func _on_stop_pressed():
	music.button_play()
	units[0].remove_job()

func _on_IslandDatas_mouse_entered():
	mouse_on_ui = true

func _on_UnitDatas_mouse_entered():
	mouse_on_ui = true

func _on_UnitsDatas_mouse_entered():
	mouse_on_ui = true

func _on_IslandDatas_mouse_exited():
	mouse_on_ui = false

func _on_UnitsDatas_mouse_exited():
	mouse_on_ui = false

func _on_UnitDatas_mouse_exited():
	mouse_on_ui = false

func _on_NewVillagerOption_mouse_entered():
	mouse_on_ui = true

func _on_NewVillagerOption_mouse_exited():
	mouse_on_ui = false

# builder
func _on_farm_pressed():
	music.button_play()
	#disable others
	if Island.building_bridge:
		Island.building_bridge = false
		Island.is_building = false
	if Island.building_house:
		Island.building_house = false
		Island.is_building = false
	
	Island.is_building = not Island.is_building
	Island.building_farm = not Island.building_farm

func _on_house_pressed():
	music.button_play()
	#disable others
	if Island.building_farm:
		Island.building_farm = false
		Island.is_building = false
	if Island.building_bridge:
		Island.building_bridge = false
		Island.is_building = false
	
	Island.is_building = not Island.is_building
	Island.building_house = not Island.building_house


func _on_attack_pressed():
	pass # Replace with function body.

func _on_bridge_pressed():
	music.button_play()
	if Island.building_farm:
		Island.building_farm = false
		Island.is_building = false
	if Island.building_house:
		Island.building_house = false
		Island.is_building = false
	Island.is_building = not Island.is_building
	Island.building_bridge = not Island.building_bridge

func show_structure_datas(structure):
	if structure.size():
		UI.update_structure_datas(structure)
		UI.show_structure_datas()
	else:
		UI.hide_structure_datas()


func _on_Building_Instructions_mouse_entered():
	mouse_on_ui = true


func _on_Building_Instructions_mouse_exited():
	mouse_on_ui = false


func _on_center_island_pressed():
	music.button_play()
	Island.center_camera()

func _on_heal_pressed():
	if units.size() > 0:
		var unit = units[0]
		if unit.get_life() < unit.get_life_max() and Island.resources.food >= 4:
			unit.set_life(unit.get_life()+4)
			Island.resources.food-=4
			UI.update_resources_datas(Island.resources)


func _on_options_pressed():
	music.button_play()
	UI.open_options()
