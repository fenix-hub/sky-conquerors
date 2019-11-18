extends Camera2D

var fixed_toggle_point = Vector2(0,0)
var multiplier_movement = 1.15
var camera_limits = [Vector2(-2048,-1200),Vector2(2048,1200)]
var speed = 350

func _process(delta):
	var ref = get_local_mouse_position()
	self.global_position -= (ref - fixed_toggle_point) * delta * multiplier_movement
	
	_snap_to_limits()

func _snap_to_limits():
	if get_zoom() == Vector2(1,1):
		self.global_position.x = clamp(self.global_position.x, camera_limits[0].x*3/4, camera_limits[1].x*3/4)
		self.global_position.y = clamp(self.global_position.y, camera_limits[0].y*3/4, camera_limits[1].y*3/4)
