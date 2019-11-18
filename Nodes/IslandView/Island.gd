extends Node2D

var VillagerEnemy = preload("res://Nodes/Villager/EnemyVillager.tscn")

onready var SelectionArea = $SelectionArea
onready var Maps = $Maps
onready var IslandMap = $Maps/IslandMap/Map
onready var IslandCells = $Maps/IslandCells
onready var IslandStructures = $Maps/IslandStructures
onready var IslandStructuresPreview = $Maps/IslandStructuresPreview
onready var Hovering = $Maps/Hovering

onready var DestinationPlaceholder = $Maps/PlaceHolders/Destination

onready var CustomCamera = $CustomCamera

var area_start_position : Vector2
var area_end_position : Vector2

var is_building : bool = false setget set_is_building,get_is_building
var building_house : bool = false
var building_farm : bool = false
var building_bridge : bool = false

var rng = RandomNumberGenerator.new()

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
	enemy_flag = 11,
	bridge = 12,
}

var prices : Dictionary = {
	'house':{
		'wood':7,
		'stone':7,
	},
	'farm':{
		'wood':5,
		'stone':3,
	},
	'soldier':{
		'food':20,
	},
	'villager':{
		'food':10,
	},
	'bridge':{
		'stone':1,
		'wood':2
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


var island_size : int
var island_position : Vector2 = Vector2()

var forests_list : Array = []
var mines_list : Array = []
var buildings_list : Array = []
var houses_list : Array = []
var farms_list : Array = []
var bridges_list : Array = []

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
	
	DestinationPlaceholder.hide()

func generate_island(island_position : Vector2, radius : int , max_forests : int , max_mines : int):
	island_size = radius
	self.island_position = island_position
	
	var forests : int = 0
	var mines : int = 0
	
	var tile_id = TILES.tile
	var rand_coord : Vector2
	# The right half of the circle:
	for x in range(island_position.x, island_position.x + radius):
	# The bottom right half of the circle:
		for y in range(island_position.y, island_position.y + radius):
			var relative_vector = Vector2(x, y) - island_position;
			if (relative_vector.length() < radius):
				IslandMap.set_cell(x, y, tile_id);
		# The top right half of the circle
		for y in range(island_position.y - radius, island_position.y):
			var relative_vector = island_position - Vector2(x, y);
			if (relative_vector.length() < radius):
				IslandMap.set_cell(x, y, tile_id);
	
	# The left half of the circle
	for x in range(island_position.x - radius, island_position.x):
		# The bottom left half of the circle:
			for y in range(island_position.y, island_position.y + radius):
				var relative_vector = Vector2(x, y) - island_position;
				if (relative_vector.length() < radius):
					IslandMap.set_cell(x, y, tile_id);
		# The top left half of the circle
			for y in range(island_position.y - radius, island_position.y):
				var relative_vector = island_position - Vector2(x, y);
				if (relative_vector.length() < radius):
					IslandMap.set_cell(x, y, tile_id);
	
	IslandStructures.set_cellv(island_position,TILES.flag)
	
	while forests < max_forests:
		rand_coord = Vector2(randi() % (int(radius)),randi() % (int(radius)))
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
		rand_coord = Vector2(randi() % (int(radius)),randi() % (int(radius)))
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
	
#	IslandMap.update_bitmask_region()
	
	while population.total < 2:
		get_parent().spawn_villager()
	
	center_camera()

func generate_other_island(island_position : Vector2, radius : int , max_forests : int , max_mines : int , populated : bool = false, amount : int = 0):
	var forests : int = 0
	var mines : int = 0
	
	
#	for x in range(island_position.x,real_size.x):
#		for y in range(island_position.y,real_size.y):
#			IslandMap.set_cellv(Vector2(x,y),TILES.tile)
	
	var tile_id = TILES.tile
	
	for x in range(island_position.x, island_position.x + radius):
	# The bottom right half of the circle:
		for y in range(island_position.y, island_position.y + radius):
			var relative_vector = Vector2(x, y) - island_position;
			if (relative_vector.length() < radius):
				IslandMap.set_cell(x, y, tile_id);
		# The top right half of the circle
		for y in range(island_position.y - radius, island_position.y):
			var relative_vector = island_position - Vector2(x, y);
			if (relative_vector.length() < radius):
				IslandMap.set_cell(x, y, tile_id);
	
	# The left half of the circle
	for x in range(island_position.x - radius, island_position.x):
		# The bottom left half of the circle:
			for y in range(island_position.y, island_position.y + radius):
				var relative_vector = Vector2(x, y) - island_position;
				if (relative_vector.length() < radius):
					IslandMap.set_cell(x, y, tile_id);
		# The top left half of the circle
			for y in range(island_position.y - radius, island_position.y):
				var relative_vector = island_position - Vector2(x, y);
				if (relative_vector.length() < radius):
					IslandMap.set_cell(x, y, tile_id);
	
	var rand_coord : Vector2
	
	
	while forests < max_forests:
		rand_coord = Vector2(
		rng.randi_range(island_position.x - radius +1  , island_position.x + radius -1),
		rng.randi_range(island_position.y - radius +1, island_position.y + radius -1)
		)
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
		rand_coord = Vector2(
		rng.randi_range(island_position.x - radius , island_position.x + radius),
		rng.randi_range(island_position.y - radius, island_position.y + radius)
		)
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
	
	if populated:
		spawn_enemy(island_position , radius, amount)
		
		var house = 0
		while house < 4:
			rand_coord = Vector2(
			rng.randi_range(island_position.x - radius , island_position.x + radius),
			rng.randi_range(island_position.y - radius, island_position.y + radius)
			)
			if IslandStructures.get_cellv(rand_coord) == -1:
				IslandStructures.set_cellv(rand_coord,TILES.house)
				IslandMap.set_cellv(rand_coord,TILES.tile_nonav)
				houses_list.append({
					'type':TILES.house,
					'description':"sombody's house",
					'map_position':rand_coord, 
					'world_position':IslandStructures.map_to_world(rand_coord), 
					'value':20, 'max':20,
					'name':"House",
				})
				house+=1
		var farm = 0
		while farm < 4:
			rand_coord = Vector2(
			rng.randi_range(island_position.x - radius , island_position.x + radius),
			rng.randi_range(island_position.y - radius, island_position.y + radius)
			)
			if IslandStructures.get_cellv(rand_coord) == -1:
				IslandStructures.set_cellv(rand_coord,TILES.farm)
				IslandMap.set_cellv(rand_coord,TILES.tile_nonav)
				farms_list.append({
					'type':TILES.farm,
					'description':"a farm to produce food for all the inhabitants of this island",
					'map_position':rand_coord, 
					'world_position':IslandStructures.map_to_world(rand_coord), 
					'value':20, 'max':20,
					'name':"Farm",
				})
				farm+=1

func spawn_enemy(from_pos : Vector2, radius : int, amount : int):
	for i in range(0,amount):
		var enemy = VillagerEnemy.instance()
		enemy.set_position(get_random_position_from(from_pos , radius))
		Maps.add_child(enemy)
		enemy.create(enemy.VILLAGER_JOBS.soldier, get_parent() , get_node("Maps/IslandMap"))

func center_camera():
	CustomCamera.move_to_position(island_position)

func get_random_position() -> Vector2:
	var real = IslandMap.map_to_world(island_position)
	var pos : Vector2
	pos.x = rand_range(real.x - 32 * island_size , real.x + 32 * island_size)
	pos.y = rand_range(real.y - 32 * island_size, real.y + 32 * island_size)
	return pos

func get_random_position_from(from_pos : Vector2 , radius : int) -> Vector2:
	var real = IslandMap.map_to_world(from_pos)
	var pos : Vector2
	pos.x = rand_range(real.x - 32*radius , real.x + 32*radius)
	pos.y = rand_range(real.y - 32*radius , real.y + 32*radius)
	return pos

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
			if buildings_list.has(structure):
				buildings_list.erase(structure)
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
					IslandMap.set_cellv(structure.map_position,TILES.tile)
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
					IslandMap.set_cellv(structure.map_position,TILES.tile)
				if structure.building == TILES.bridge:
					bridges_list.append({'type':TILES.bridge,
					'name':"Bridge",
					'description':"a bridge to connect islands",
					'building':TILES.bridge,
					'map_position':structure.map_position, 
					'world_position':structure.world_position, 
					'value':0, 'max':5})
					IslandMap.set_cellv(structure.map_position,TILES.bridge)

func _process(delta):
	if not get_parent().mouse_on_ui:
		handle_input()

func handle_input():
	var event_position = get_global_mouse_position()
	
	
	# Selection Area -----------------------
	
	if Input.is_action_just_pressed("click_left"):
		is_dragging = true
		area_start_position = get_global_mouse_position()
	if is_dragging:
		area_end_position = event_position
		SelectionArea.rect_position = area_start_position
		draw_arearect()
	
	if Input.is_action_just_released("click_left"):
		if area_start_position.distance_to(area_end_position) > 32:
			emit_signal("select_in_area",area_start_position,area_end_position)
		is_dragging = false
		area_start_position = Vector2()
		area_end_position = Vector2()
		SelectionArea.rect_position = area_start_position
		SelectionArea.rect_size = Vector2(abs(area_start_position.x - area_end_position.x),abs(area_start_position.y - area_end_position.y))
	
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
						if forest.size() and forest.map_position == event_map_position:
							structure = forest
				TILES.mine:
					for mine in mines_list:
						if mine.size() and mine.map_position == event_map_position:
							structure = mine
				TILES.building:
					for building in buildings_list:
						if  building.size() and building.map_position == event_map_position:
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
			DestinationPlaceholder.hide()
			
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
					var building_structure = {'type':Villager.VILLAGER_JOBS.builder,
					'name':"Building",
					'description':"A base for a new structure",
					'building':building_type,
					'map_position':event_map_position, 
					'world_position':IslandStructures.map_to_world(event_map_position), 
					'value':0, 'max':20}
					
					buildings_list.append(building_structure)
					
					emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.builder, building_structure)
			else:
				var structure = {}
				match IslandStructures.get_cellv(event_map_position):
					TILES.forest:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						selected_structure = event_map_position
						for forest in forests_list:
							if forest.size() and forest.map_position == event_map_position:
								structure = forest
					TILES.mine:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						selected_structure = event_map_position
						for mine in mines_list:
							if mine.size() and mine.map_position == event_map_position:
								structure = mine
					TILES.farm:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						for farm in farms_list:
							if farm.size() and farm.map_position == event_map_position:
								structure = farm
					TILES.house:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						for house in houses_list:
							if house.size() and house.map_position == event_map_position:
								structure = house
					TILES.flag:
						IslandCells.set_cellv(selected_structure,TILES.empty)
						IslandCells.set_cellv(event_map_position,TILES.cell_selected)
						structure = {
						'type':TILES.flag,
						'description':"a totem representing your island: with enough resources you can spawn new villagers or soldiers",
						'name':"Your Village Totem",
						'map_position':event_map_position, 
						'world_position':IslandStructures.map_to_world(event_map_position), 
						'value':population.total, 'max':population.max}
					_:
						IslandCells.clear()
						selected_structure = Vector2()
				emit_signal("show_structure_datas",structure)
		
		#click right -> selection
		if Input.is_action_just_pressed("click_right"):
			DestinationPlaceholder.hide()
			var mouse_position = get_global_mouse_position()
			
			match IslandStructures.get_cellv(event_map_position):
				TILES.forest:
					if get_parent().get_units() > 0:
						for forest in forests_list:
							if forest.size() and  forest.map_position == event_map_position:
								emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.woodcutter, forest)
				TILES.mine:
					if get_parent().get_units() > 0:
						for mine in mines_list:
							if mine.size() and mine.map_position == event_map_position:
								emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.miner, mine)
				TILES.farm:
					if get_parent().get_units() > 0:
						for farm in farms_list:
							if farm.size() and farm.map_position == event_map_position:
								emit_signal("set_selected_villager_job",Villager.VILLAGER_JOBS.farmer, farm)
				TILES.house:
					pass
				-1:
					if is_building:
						is_building = not is_building
						building_farm = false
						building_house = false
					else:
						DestinationPlaceholder.set_position(mouse_position)
						DestinationPlaceholder.show()
						emit_signal("set_destination",mouse_position)
	else:
		IslandStructuresPreview.clear()
		if is_building and building_bridge:
			Hovering.set_cellv(event_map_position,TILES.cell_hovering)
			IslandStructuresPreview.set_cellv(event_map_position,TILES.bridge)
			
			if Input.is_action_just_pressed("click_left"):
				if resources.wood >= prices.bridge.wood and resources.stone >= prices.bridge.stone:
					resources.wood-=prices.bridge.wood
					resources.stone-=prices.bridge.stone
				else:
					return
				
				get_parent().UI.set_wood(resources.wood)
				get_parent().UI.set_stone(resources.stone)
				
#				var building_structure = {'type':Villager.VILLAGER_JOBS.builder,
#				'name':"Bridge",
#				'description':"a bridge to connect islands",
#				'building':TILES.bridge,
#				'map_position':event_map_position, 
#				'world_position':IslandMap.map_to_world(event_map_position), 
#				'value':0, 'max':5}
#
#				buildings_list.append(building_structure)
#
#				emit_signal("set_selected_villager_job", Villager.VILLAGER_JOBS.builder, building_structure)
				
				IslandMap.set_cellv(event_map_position,TILES.bridge)
				
			if Input.is_action_just_pressed("click_right"):
				set_is_building(false)
				building_bridge = false
		
		Hovering.clear()
		get_parent().TilemapDatas.hide_structure_status()
		IslandCells.clear()
		if Input.is_action_just_pressed("click_left"):
			emit_signal("deselect_all_units")
			IslandCells.clear()
			DestinationPlaceholder.hide()

func draw_arearect():
	SelectionArea.rect_size = Vector2(abs(area_start_position.x - area_end_position.x),abs(area_start_position.y - area_end_position.y))
	if area_start_position.x > area_end_position.x:
		if SelectionArea.rect_scale.x != -1:
			SelectionArea.rect_scale.x *= -1
	else:
		if SelectionArea.rect_scale.x == -1:
			SelectionArea.rect_scale.x *= -1
	
	if area_start_position.y > area_end_position.y:
		if SelectionArea.rect_scale.y != -1:
			SelectionArea.rect_scale.y *= -1
	else:
		if SelectionArea.rect_scale.y == -1:
			SelectionArea.rect_scale.y *= -1

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
