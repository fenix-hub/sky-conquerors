extends Sprite

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var velocity = Vector2(50,0)
export var pos = Vector2(0,-14)
export (float) var max_pos = 1728

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	translate(velocity * delta)
	
	if position.x >= max_pos :
		position = pos
