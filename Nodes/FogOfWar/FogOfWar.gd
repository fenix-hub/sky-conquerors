extends TileMap

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func remove_fog_area(area : Rect2):
	for x in range(area.position.x-2,area.end.x+2):
		for y in range(area.position.y-2,area.end.y+2):
			set_cellv(Vector2(x,y),-1)

func remove_fog_cell(island_position, radius=4, tile_id=-1):
# The right half of the circle:
	for x in range(island_position.x, island_position.x + radius):
	# The bottom right half of the circle:
		for y in range(island_position.y, island_position.y + radius):
			var relative_vector = Vector2(x, y) - island_position;
			if (relative_vector.length() < radius):
				set_cell(x, y, tile_id);
		# The top right half of the circle
		for y in range(island_position.y - radius, island_position.y):
			var relative_vector = island_position - Vector2(x, y);
			if (relative_vector.length() < radius):
				set_cell(x, y, tile_id);
		# The left half of the circle
	for x in range(island_position.x - radius, island_position.x):
		# The bottom left half of the circle:
		for y in range(island_position.y, island_position.y + radius):
			var relative_vector = Vector2(x, y) - island_position;
			if (relative_vector.length() < radius):
				set_cell(x, y, tile_id);
		# The top left half of the circle
		for y in range(island_position.y - radius, island_position.y):
			var relative_vector = island_position - Vector2(x, y);
			if (relative_vector.length() < radius):
				set_cell(x, y, tile_id);
