extends PanelContainer

onready var StructureName = $DataContainer/Datas/Name/value
onready var StructureLife = $DataContainer/Datas/Life/ProgressBar
onready var StructureIcon = $DataContainer/Sprite
onready var StructureDescription = $DataContainer/Datas/description

onready var StructureOption = $DataContainer/NewVillagerOption

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
