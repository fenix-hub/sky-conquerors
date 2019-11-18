extends PanelContainer

onready var UnitLife = $DataContainer/Datas/Life/ProgressBar
onready var UnitName = $DataContainer/Datas/Name/value
onready var UnitAge = $DataContainer/Datas/Age/value
onready var UnitJob = $DataContainer/Datas/Job/value
onready var UnitItems = $DataContainer/Datas/Items/value
onready var UnitTexture = $DataContainer/Sprite
onready var UnitJobs = $DataContainer/Jobs
onready var UnitActions = $DataContainer/Actions

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
