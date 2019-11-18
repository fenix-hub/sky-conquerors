extends Camera2D
class_name CustomCamera

var fixed_toggle_point = Vector2(0,0)
var multiplier_movement = 1.3
var camera_limits = [Vector2(-2048,-1200),Vector2(2048,1200)]
var speed = 350

func _process(delta):
	# This happens once 'move_map' is pressed
	if Input.is_action_just_pressed("mouse_wheel_pressed"):
		var ref = get_local_mouse_position()
		fixed_toggle_point = ref
	# This happens while 'move_map' is pressed
	if Input.is_action_pressed("mouse_wheel_pressed"):
		slide_map_around(delta)
	
	slide_map(delta)
	
	_snap_to_limits()

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
		# zoom in
			if event.button_index == BUTTON_WHEEL_UP:
				zoom_camera(-1)
				# call the zoom function
			# zoom out
			if event.button_index == BUTTON_WHEEL_DOWN:
				zoom_camera(1)
			# call the zoom function
	if event is InputEventKey:
		if event.is_action_released("zoom_in"):
			zoom_camera(-1)
		if event.is_action_released("zoom_out"):
			zoom_camera(1)

# slides the map around
func slide_map_around(delta : float):
	var ref = get_local_mouse_position()
	self.global_position -= (ref - fixed_toggle_point) * delta * multiplier_movement

# slides the map with WASD
func slide_map(delta:float):
	var direction = Vector2()
	direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	
	self.global_position += direction.normalized() * delta * multiplier_movement * speed

# zoom in and out based on value
func zoom_camera(amount : float):
	if amount > 0:
		if get_zoom() < Vector2(4,4):
			set_zoom(get_zoom()/0.5)
	else:
		if get_zoom() > Vector2(1,1):
			set_zoom(get_zoom()*0.5)

# slide camera to this position
func move_to_position(destination : Vector2):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self,"position",self.global_position,destination,0.7,Tween.TRANS_EXPO,Tween.EASE_IN_OUT)
	tween.start()
	yield(tween,"tween_all_completed")
	tween.queue_free()

func _snap_to_limits():
	if get_zoom() == Vector2(4,4):
		self.global_position.x = 0
		self.global_position.y = 0
	if get_zoom() == Vector2(2,2):
		self.global_position.x = clamp(self.global_position.x, camera_limits[0].x / 2, camera_limits[1].x / 2)
		self.global_position.y = clamp(self.global_position.y, camera_limits[0].y / 2, camera_limits[1].y / 2) 
	if get_zoom() == Vector2(1,1):
		self.global_position.x = clamp(self.global_position.x, camera_limits[0].x*3/4, camera_limits[1].x*3/4)
		self.global_position.y = clamp(self.global_position.y, camera_limits[0].y*3/4, camera_limits[1].y*3/4)
	if get_zoom() == Vector2(0.5,0.5):
		self.global_position.x = clamp(self.global_position.x, camera_limits[0].x*7/8, camera_limits[1].x*7/8)
		self.global_position.y = clamp(self.global_position.y, camera_limits[0].y*7/8, camera_limits[1].y*7/8)
