extends Node2D

onready var IslandMap = $Maps/IslandMap/Map
onready var IslandCells = $Maps/IslandCells
onready var IslandStructures = $Maps/IslandStructures
onready var IslandStructuresPreview = $Maps/IslandStructuresPreview
onready var Hovering = $Maps/Hovering
onready var NavigationMap = $Maps/IslandMap

var area_start_position : Vector2
var area_end_position : Vector2

var is_building : bool = false setget set_is_building,get_is_building
var building_house : bool = false
var building_farm : bool = false

enum TILES {
	tile = 4,
	tile_nonav = 5,
	cell_hovering = 1,
	cell_selected = 6,
	forest = 2,
	mine = 3
	empty = -1,
	building = 7,
	farm = 8,
	house = 9,
	flag = 10,
}

var prices : Dictionary = {
	'house':{
		'wood':5,
		'stone':5,
	},
	'farm':{
		'wood':8,
		'stone':3,
	},
	'soldier':{
		'food':35,
	},
	'villager':{
		'food':20,
	}
}

var resources : Dictionary = {
	'wood':0,
	'stone':0,
	'food':0
}

var structures : Dictionary = {
	'forests':0,
	'mines':0,
	'houses':0,
	'buildings':0,
	'farms':0,
}

var population : Dictionary = {
	'villagers':0,
	'soldiers':0,
	'woodcutters':0,
	'farmers':0,
	'miners':0,
	'builders':0,
	'total':0,
	'max':2
}


var island_size : Vector2 = Vector2()

var forests_list : Array = []
var mines_list : Array = []
var buildings_list : Array = []
var houses_list : Array = []
var farms_list : Array = []

var selected_structure : Vector2 = Vector2()

var is_dragging : bool = false

signal set_destination(destination)
signal deselect_all_units()
signal select_in_area(selection_area)
signal set_selected_villager_job(job)
signal show_structure_status(structure)
signal show_structure_datas(structure)

func _ready():
	randomize()
	clear_maps()
	
	connect("set_destination",get_parent(),"set_unit_destination")
	connect("deselect_all_units",get_parent(),"deselect_all_units")
	connect("select_in_area",get_parent(),"select_in_area")
	connect("set_selected_villager_job",get_parent(),"set_villager_job")
	connect("show_structure_status",get_parent(),"show_structure_status")
	connect("show_structure_datas",get_parent(),"show_structure_datas")


func generate_island(size : Vector2 , max_forests : int , max_mines : int):
	island_size = size
	
	var forests : int = 0
	var mines : int = 0
	
	for x in range(0,island_size.x):
		for y in range(0,island_size.y):
			IslandMap.set_cellv(Vector2(x,y),TILES.tile)
			
			if x == floor(island_size.x/2) and y == floor(island_size.y/2):
				IslandStructures.set_cellv(Vector2(x,y),TILES.flag)
	
	var rand_coord : Vector2
	
	while forests < max_forests:
		rand_coord = Vector2(randi() % (int(island_size.x)),randi() % (int(island_size.y)))
		if IslandStructures.get_cellv(rand_coord) == -1:
			IslandStructures.set_cellv(rand_coord,TILES.forest)
			IslandMap.set_cellv(rand_coord,TILES.tile_nonav)
			forests_list.append({'type':Villager.VILLAGER_JOBS.woodcutter,
			'map_position':rand_coord, 
			'world_position':IslandStructures.map_to_world(rand_coord), 
			'name':"Forest",
			'value':20, 'max':20,
			'description':"a forest to gather the wood you need to build new structures"})
			forests+=1
	
	while mines < max_mines:
		rand_coord = Vector2(randi() % (int(island_size.x)),randi() % (int(island_size.y)))
		if IslandStructures.get_cellv(rand_coord) == -1:
			IslandStructures.set_cellv(rand_coord,TILES.mine)
			IslandMap.set_cellv(rand_coord,TILES.tile_nonav)
			mines_list.append({'type':Villager.VILLAGER_JOBS.miner,
			'map_position':rand_coord, 
			'world_position':IslandStructures.map_to_world(rand_coord), 
			'name':"Stonemine",
			'value':20, 'max':20,
			'description':"a minestone to gather the stone you need to build new structures"})
			mines+=1

func get_random_position() -> Vector2:
	var cells = IslandMap.get_used_cells()
	for cell in IslandMap.get_used_cells():
		if IslandMap.get_cellv(cell) != TILES.tile:
			cells.erase(cell)
	
	var rand_index = randi() % cells.size()
	return IslandMap.map_to_world(cells[rand_index]) + Vector2(rand_range(-8,8),rand_range(-8,8))

func destroy_structure(structure : Dictionary) :
	IslandStructures.set_cellv(structure.map_position,-1)
	IslandMap.set_cellv(structure.map_position,TILES.tile)
	match structure.type:
		Villager.VILLAGER_JOBS.miner:
			if mines_list.has(structure):
				mines_list.erase(structure)
		Villager.VILLAGER_JOBS.woodcutter:
			if forests_list.has(structure):
				forests_list.erase(structure)
		Villager.VILLAGER_JOBS.builder:
			IslandMap.set_cellv(structure.map_position,TILES.tile_nonav)
			IslandStructures.set_cellv(structure.map_position,structure.building)
			if structure.building == TILES.house:
				houses_list.append({
					'type':TILES.house,
					'description':"a house to increase the number of maximum inhabitants of this island (population max +1)",
					'map_position':structure.map_position, 
					'world_position':structure.world_position, 
					'value':20, 'max':20,
					'name':"House",
				})
				population.max += 1
				get_parent().UI.update_population_datas(population)
			if structure.building == TILES.farm:
				farms_list.append({
					'type':TILES.farm,
					'description':"a farm to produce food for all the inhabitants of your island (you can feed new inhabitants or soldiers)",
					'map_position':structure.map_position, 
					'world_position':structure.world_position, 
					'value':20, 'max':20,
					'name':"Farm"
				})
			buildings_list.erase(structure)

func _process(delta):
	if not get_parent().mouse_on_ui:
		handle_input()

func handle_input():
	var event_position = get_global_mouse_position()
	
	# ---------------------------------------
	
	event_position += Vector2(0,32)
	var event_map_position = IslandMap.world_to_map(event_position)
	
	if IslandMap.get_cellv(event_map_position) > -1 :
		#hovering
		Hovering.clear()
		get_parent().TilemapDatas.hide_structure_status()
		
		if IslandStructures.get_cellv(event_map_position) > -1:
			Hovering.set_cellv(event_map_position,TILES.cell_hovering)
			
			# --- infos about structure
			
			var structure : Dictionary = {}
			match IslandStructures.get_cellv(event_map_position):
				TILES.forest:
					for forest in forests_list:
						if forest.map_position == event_map_position:
							structure = forest
				TILES.mine:
					for mine in mines_list:
						if mine.map_position == event_map_position:
							structure = mine
				TILES.building:
					for building in buildings_list:
						if building.map_position == event_map_position:
							structure = building
			if structure.size():
				emit_signal("show_structure_status",structure)
		
		
		# -- preview for building
		IslandStructuresPreview.clear()
		if is_building :
			Hovering.set_cellv(event_map_position,TILES.cell_hovering)
			if building_farm:
				IslandStructuresPreview.set_cellv(event_map_position,TILES.farm)
			if building_house:
				IslandStructuresPreview.set_cellv(event_map_position,TILES.house)
		
		
		#click left -> infos
		if Input.is_action_just_pressed("click_left"):
			# building process
			if is_building:
				var building_type : int
				if IslandStructures.get_cellv(event_map_position) == -1:
					if building_farm and resources.wood >= prices.farm.wood and resources.stone >= prices.farm.stone:
						resources.wood-=prices.farm.wood
						resources.stone-=prices.farm.wood
						building_type = TILES.farm
					elif building_house and resources.wood >= prices.house.wood and resources.stone >= prices.house.stone:
						resources.wood-=prices.house.wood
						resources.stone-=prices.house.wood
						building_type = TILES.house
					else:
						return
					
					get_parent().UI.set_wood(resources.wood)
					get_parent().UI.set_stone(resources.stone)
					IslandStructures.set_cellv(event_map_position,TILES.building)
					IslandMap.set_cellv(event_map_position,TILES.tile_nonav)
					set_is_building(false)
					
					#create a building entity with datas
					buildings_list.append(
					{'type':Villager.VILLAGER_JOBS.builder,
					'name':"Building",
					'description':"A base for a new structure",
					'building':building_type,
					'map_position':event_map_position, 
					'world_position':IslandStructures.map_to_world(event_map_position), 
					'value':0, 'max':20})
					
					emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.builder, buildings_list)
			else:
				var structure = {}
				match IslandStructures.get_cellv(event_map_position):
					TILES.forest:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						selected_structure = event_map_position
						for forest in forests_list:
							if forest.map_position == event_map_position:
								structure = forest
					TILES.mine:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						selected_structure = event_map_position
						for mine in mines_list:
							if mine.map_position == event_map_position:
								structure = mine
					TILES.farm:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						for farm in farms_list:
							if farm.map_position == event_map_position:
								structure = farm
					TILES.house:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						for house in houses_list:
							if house.map_position == event_map_position:
								structure = house
					TILES.flag:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						structure = {
						'type':TILES.flag,
						'description':"a flag representing your island: with enough resources you can spawn new villagers or soldiers",
						'name':"Your Village Flag",
						'map_position':event_map_position, 
						'world_position':IslandStructures.map_to_world(event_map_position), 
						'value':population.total, 'max':population.max}
					_:
						IslandCells.clear()
						selected_structure = Vector2()
				emit_signal("show_structure_datas",structure)
		
		#click right -> selection
		if Input.is_action_just_pressed("click_right"):
			var mouse_position = get_global_mouse_position()
			
			match IslandStructures.get_cellv(event_map_position):
				TILES.forest:
					if get_parent().get_units() > 0:
						emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.woodcutter, forests_list)
				TILES.mine:
					if get_parent().get_units() > 0:
						emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.miner, mines_list)
				TILES.farm:
					if get_parent().get_units() > 0:
						emit_signal("set_selected_villager_job",Villager.VILLAGER_JOBS.farmer, farms_list)
				TILES.house:
					pass
				-1:
					if is_building:
						is_building = not is_building
						building_farm = false
						building_house = false
					else:
						emit_signal("set_destination",mouse_position)
	else:
		Hovering.clear()
		IslandStructuresPreview.clear()
		get_parent().TilemapDatas.hide_structure_status()
		IslandCells.clear()
		if Input.is_action_just_pressed("click_left"):
			emit_signal("deselect_all_units")
			IslandCells.clear()

func clear_maps():
	IslandCells.clear()
	IslandMap.clear()
	IslandStructures.clear()
	IslandStructuresPreview.clear()
	Hovering.clear()

func set_is_building(value : bool):
	is_building = value
	get_parent().UI.BuildingInstructions.set_visible(is_building)

func get_is_building() -> bool:
	return is_building
