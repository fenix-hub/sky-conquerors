extends RigidBody2D
class_name Villager

onready var LifeBar = $Sprite/Hover/LifeBar
onready var Hover = $Sprite/Hover
onready var VillagerSprite = $Sprite

onready var JobTimer = $JobTimer

const TYPE = "Villager"

var rng = RandomNumberGenerator.new()

enum VILLAGER_JOBS { villager , farmer , woodcutter , miner , builder , soldier }
enum OUTLINES {normal, hover, selected, empty, woodcutter, miner, farmer, builder, soldier }
enum SPRITES {villager = 0 , woodcutter = 4, miner = 5, farmer = 6 , builder = 7 , soldier = 8}

export (String) var villager_name : String = "" setget set_name, get_name
export (float) var villager_life : float = 0.0 setget set_life,get_life
export (float) var villager_life_max : float = 0.0 setget set_life_max,get_life_max
export (int) var villager_age : int = 0 setget set_age,get_age
export (int) var villager_job : int = 0 setget set_job, get_job
export (Array) var items : Array = [] setget set_items, get_items
export (int) var items_max : int setget set_items_max , get_items_max

var villager_datas : Dictionary = {} setget set_datas,get_datas
var selected : bool = false
var world_node : Node 
var navigation_map : Navigation2D
var path : PoolVector2Array = []

var structure_to_work : Dictionary = {}

var speed = 100

var working : bool = false
var stop_working : bool = true
var moving : bool = false

var is_attacking : bool = false
var enemies : Array = []
var attack_timer = 0
var damage = 3

var dead = false

export (int) var extract_amount : int = 1  # how much this villager can extract in terms of resources

signal selected(villager)
signal deselected(villager)
signal get_resource(villager, amount)
signal update_villager_ui(villager)
signal dead(villager)

func _ready():
	randomize()
	
	$blood.emitting=false
	$gathering.emitting=false
	
	rng.randomize()
	LifeBar.hide()
	update_ui()
	VillagerSprite.set_frame(SPRITES.villager)
	Hover.set_frame(OUTLINES.normal)
	linear_velocity = Vector2(0,0)

func create(j : int , world : Node , navigation_map_node : Navigation2D) -> void:
	villager_name = generate_random_name()
	villager_age = 0
	villager_job = j
	if villager_job != VILLAGER_JOBS.soldier:
		villager_life = 10
		items_max = 5
	else:
		villager_life = 20
		items_max = 2
		VillagerSprite.set_frame(SPRITES.soldier)
		Hover.set_frame(SPRITES.soldier)
		
	villager_life_max = villager_life
	villager_datas = {
		'name':villager_name,
		'life':villager_life,
		'life_max':villager_life_max,
		'age':villager_age,
		'job':villager_job,
		'items':items,
		'items_max':items_max,
	}
	world_node = world
	navigation_map = navigation_map_node
	
	if villager_job == VILLAGER_JOBS.soldier:
		$SoldierArea.monitoring = true
	else:
		$SoldierArea.monitoring = false
	
	connect("selected",world_node,"select_unit")
	connect("deselected",world_node,"deselect_unit")
	connect("get_resource",world_node,"get_resource_from")
	connect("update_villager_ui",world_node,"update_villager_ui")
	connect("dead",world_node,"villager_dead")
	
	add_to_group("villagers")

func move_to(destination : Vector2):
	moving = true
	path = navigation_map.get_simple_path(self.position,destination,false)
	if path.size():
		path[path.size()-1] += Vector2(rng.randi_range(-20,20),rng.randi_range(-20,20))

func _physics_process(delta):
	var text = str(working)+" "+str(moving)+" "+str(path.size())+" "+str(stop_working)+" "+str(structure_to_work.size())
	$Label.set_text(text)
	move_villager()
	do_job(villager_job)

func move_villager():
	if path.size() > 0 and not dead:
		var distance = global_position.distance_to(path[0])
		if distance > 3:
			linear_velocity = global_position.direction_to(path[0]) * speed
			remove_fog()
		else:
			linear_velocity = Vector2()
			path.remove(0)
	else:
		linear_velocity = Vector2()
		moving = false

func remove_fog():
	if world_node.FogOfWar.get_cellv(world_node.FogOfWar.world_to_map(position)) != -1:
		world_node.FogOfWar.remove_fog_cell(world_node.FogOfWar.world_to_map(position))

func do_job(job : int):
	match job:
		VILLAGER_JOBS.villager:
			working = false
			$gathering.emitting = false
		VILLAGER_JOBS.woodcutter:
			cut_wood()
		VILLAGER_JOBS.miner:
			mine_stone()
		VILLAGER_JOBS.builder:
			build_structure()
		VILLAGER_JOBS.farmer:
			get_food()
		VILLAGER_JOBS.soldier:
			kill_enemies()

func cut_wood():
	if not working and not moving and not stop_working:
		JobTimer.wait_time = 1
		$gathering.lifetime = 1
		JobTimer.start()
		working = true

func mine_stone():
	if not working and not moving and not stop_working:
		JobTimer.wait_time = 1
		$gathering.lifetime = 1
		JobTimer.start()
		working = true

func build_structure():
	if not working and not moving and not stop_working:
		JobTimer.wait_time = 1
		$gathering.lifetime = 1
		JobTimer.start()
		working = true

func get_food():
	if not working and not moving and not stop_working:
		JobTimer.wait_time = 1
		$gathering.lifetime = 1
		JobTimer.start()
		working = true

func kill_enemies():
	if not dead:
		if enemies.size() > 0 and path.size() < 1 and enemies[0].visible:
			move_to(enemies[0].position)

func _on_JobTimer_timeout():
	# farmer , woodcutter , miner , builder , soldier -> resources = 1 , 2 , 3
	# this VILLAGER with @villager_job  extracts an @extract_amount from @villager.structure_to_work[0]
	if working and not moving and stop_working == false:
		$gathering.emitting = true
		emit_signal("get_resource", self, extract_amount)
	elif is_attacking:
		enemies[0].take_damage(damage,self)
	else:
		$blood.emitting = false
		$gathering.emitting = false
		JobTimer.stop()

func _on_Area_input_event(viewport, event, shape_idx):
	# Shift for multiple selections
	if event is InputEventMouseButton:
		if event.is_pressed() and event.get_button_index() == 1:
			if not selected:
				set_selected(true)
			else:
				set_selected(false)

func _on_Area_mouse_entered():
	if not selected :
		LifeBar.show()
		Hover.set_frame(OUTLINES.hover)

func _on_Area_mouse_exited():
	if not selected :
		LifeBar.hide()
		if villager_job!=VILLAGER_JOBS.soldier:
			Hover.set_frame(OUTLINES.normal)
		else:
			Hover.set_frame(SPRITES.soldier)

func set_selected(val : bool):
	selected = val
	if val:
		Hover.set_frame(OUTLINES.selected)
		LifeBar.show()
		emit_signal("selected",self)
	else:
		if villager_job!=VILLAGER_JOBS.soldier:
			Hover.set_frame(OUTLINES.normal)
		else:
			Hover.set_frame(SPRITES.soldier)
		LifeBar.hide()
		emit_signal("deselected",self)

func update_ui():
	LifeBar.max_value = villager_life_max
	LifeBar.set_value(villager_life)


# -------------------------------------------


func set_name(n : String) -> void:
	villager_name = n
	villager_datas.name = villager_name
	emit_signal("update_villager_ui",self)

func get_name() -> String:
	return villager_name

func set_life(l : float) -> void:
	villager_life = l
	villager_datas.life = villager_life
	update_ui()
	emit_signal("update_villager_ui",self)

func get_life() -> float:
	return villager_life

func set_life_max(l : float) -> void:
	villager_life_max = l
	villager_datas.life_max = villager_life_max
	emit_signal("update_villager_ui",self)

func get_life_max() -> float:
	return villager_life_max

func set_age(a : int) -> void:
	villager_age = a
	villager_datas.age = villager_age
	emit_signal("update_villager_ui",self)

func get_age() -> int:
	return villager_age

func set_job(j : int) -> void:
	if villager_job!=VILLAGER_JOBS.soldier:
		villager_job = j
		villager_datas.job = villager_job
		var sprite
		match j:
			VILLAGER_JOBS.woodcutter:
				sprite = SPRITES.woodcutter
				$gathering.set_texture(VillagerTexture.get_item_texture("wood"))
			VILLAGER_JOBS.villager:
				sprite = SPRITES.villager
			VILLAGER_JOBS.miner:
				sprite = SPRITES.miner
				$gathering.set_texture(VillagerTexture.get_item_texture("stone"))
			VILLAGER_JOBS.farmer:
				sprite = SPRITES.farmer
				$gathering.set_texture(VillagerTexture.get_item_texture("food"))
			VILLAGER_JOBS.builder:
				sprite = SPRITES.builder
				$gathering.set_texture(VillagerTexture.get_item_texture("work"))
			VILLAGER_JOBS.soldier:
				sprite = SPRITES.soldier
		VillagerSprite.set_frame(sprite)
		stop_working = false
		emit_signal("update_villager_ui",self)

func get_job() -> int:
	return villager_job

func set_datas(d : Dictionary) -> void:
	villager_datas = d
	emit_signal("update_villager_ui",self)

func get_datas() -> Dictionary:
	return villager_datas

func set_items(i : Array) -> void:
	items = i
	villager_datas.items = i
	emit_signal("update_villager_ui",self)

func get_items() -> Array:
	return items

func set_items_max(i : int) -> void:
	items_max = i
	villager_datas.items_max = i
	emit_signal("update_villager_ui",self)

func get_items_max() -> int:
	return items_max

func add_job_position(job_data : Dictionary):
	structure_to_work = job_data
	if not working:
		move_to(job_data.world_position)

func remove_job_position(job_position : Dictionary):
	if structure_to_work.size():
		structure_to_work = {}
		working = false
		JobTimer.stop()
		world_node.Island.population.villagers+=1
		set_job(VILLAGER_JOBS.villager)

func remove_job():
	working = false
	JobTimer.stop()
	$gathering.emitting=false
	structure_to_work = {}
	match villager_job:
		VILLAGER_JOBS.villager:
			world_node.Island.population.villagers-=1
		VILLAGER_JOBS.farmer:
			world_node.Island.population.farmers-=1
		VILLAGER_JOBS.woodcutter:
			world_node.Island.population.woodcutters-=1
		VILLAGER_JOBS.miner:
			world_node.Island.population.miners-=1
		VILLAGER_JOBS.builder:
			world_node.Island.population.builders-=1
		VILLAGER_JOBS.soldier:
			world_node.Island.population.soldiers-=1
	set_job(VILLAGER_JOBS.villager)

func stop_working():
	working = false
	JobTimer.stop()
	$gathering.emitting = false
	$blood.emitting = false
	stop_working = true
	structure_to_work = {}

func add_item(item : int , amount : int):
	for x in range(0,amount):
		items.append(item)

func generate_random_name() -> String:
	var random_number = randi() % 15
	var random_name : String
	match random_number:
		0:
			random_name = "Gummlox"
		1:
			random_name = "Bumbor"
		2:
			random_name = "Jumborf"
		3:
			random_name = "Frudon"
		4:
			random_name = "Tunko"
		5:
			random_name = "Ambrax"
		6:
			random_name = "Nuclox"
		7:
			random_name = "Guidubb"
		8:
			random_name = "Saurab"
		9:
			random_name = "Piscub"
		10:
			random_name = "Stellix"
		11:
			random_name = "Luconk"
		12:
			random_name = "Burzuddan"
		13:
			random_name = "Badubadu"
		14:
			random_name = "Sdrubak"
	return random_name


func _on_SoldierArea_body_entered(body):
	if body.get("TYPE") == "Enemy" and not body.dead:
		add_enemy(body)

func add_enemy(enemy : RigidBody2D):
	if not enemies.has(enemy):
		enemies.append(enemy)

func remove_enemy(enemy : RigidBody2D):
	if enemies.has(enemy):
		enemies.erase(enemy)
	if enemies.size() < 1:
		is_attacking = false

func _on_SoldierArea_body_exited(body):
	if body.get("TYPE") == "Enemy" and not body.dead:
		remove_enemy(body)
	
	if enemies.size() < 1:
		linear_velocity = Vector2()

func take_damage(damage : int , enemy : RigidBody2D):
	$blood.emitting = true
	villager_life-=damage
	print(villager_life)
	set_life(villager_life)
	if villager_life < 1 and not dead and visible:
		dead = true
		visible = false
		$SoldierArea.monitorable = false
		for e in get_tree().get_nodes_in_group("enemies"):
			e.remove_enemy(self)
		emit_signal("dead",self)
		queue_free()


func _on_DeathTimer_timeout():
	queue_free()


func _on_Villager_body_entered(collider):
	if moving and villager_job == VILLAGER_JOBS.soldier:
		if collider.get("TYPE") == "Enemy":
			if enemies.size()>0:
				is_attacking = true
				JobTimer.wait_time = 1
				$blood.lifetime = 1
				JobTimer.start()
			else:
				is_attacking = false


func _on_Villager_body_exited(body):
	pass # Replace with function body.
