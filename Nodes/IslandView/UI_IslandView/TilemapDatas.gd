extends CanvasLayer

onready var BuildingStatus = $BuildingStatus

func _ready():
	BuildingStatus.hide()

func hide_structure_status():
	BuildingStatus.hide()

func show_structure_status(structure) :
	BuildingStatus.set_value(structure.value)
	BuildingStatus.max_value = structure.max
	BuildingStatus.ProgressValue.set_text(str(structure.value))
	BuildingStatus.ProgressMax.set_text(str(structure.max))
	BuildingStatus._set_position(structure.world_position - Vector2(64,80))
	
	BuildingStatus.show()
