extends PanelContainer
class_name GeneralButton

var unit : Villager

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_normal_texture(texture):
	$GeneralButton.set_normal_texture(texture)
