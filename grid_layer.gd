extends Node2D

# Reference to ground tile layer
@onready var ground_layer: TileMapLayer = %GroundLayer

# Grid state and appearance settings
var grid_state : bool = true
var grid_start : Vector2 = Vector2(0,0)
var grid_end  : Vector2 = Vector2(0,0)

# Minor/major line colors — share alpha for fade effect
var grid_color_minor: Color = Color(1, 1, 1, 0.2)  # faint minor lines
var grid_color_major: Color = Color(1, 1, 1, 0.5)  # stronger major lines
var grid_halfwidth : float = 1.0

# Tile size in pixels at zoom = 1
const TILE_SIZE : float = 16.0

# Major line frequency (every N tiles draw a bigger box line)
const MAJOR_LINE_EVERY : int = 10

func _draw() -> void:
	if grid_color_major.a > 0.01:
		print("grid state: ", grid_state)

		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam == null:
			return

		# Get the visible world rect directly from the camera
		var half_size: Vector2 = get_viewport().size * 0.5 / cam.zoom
		var top_left: Vector2 = cam.global_position - half_size
		var bottom_right: Vector2 = cam.global_position + half_size

		# --- Align grid to the TileMap's world origin ---
		var map_origin: Vector2 = ground_layer.global_position
		# If Tile Origin = Center, uncomment next line:
		# map_origin += Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

		var start_x: float = floor((top_left.x - map_origin.x) / TILE_SIZE) * TILE_SIZE + map_origin.x
		var end_x: float   = ceil((bottom_right.x - map_origin.x) / TILE_SIZE) * TILE_SIZE + map_origin.x
		var start_y: float = floor((top_left.y - map_origin.y) / TILE_SIZE) * TILE_SIZE + map_origin.y
		var end_y: float   = ceil((bottom_right.y - map_origin.y) / TILE_SIZE) * TILE_SIZE + map_origin.y

		# Vertical lines
		for x in range(int(start_x), int(end_x) + 1, int(TILE_SIZE)):
			var color: Color = grid_color_minor
			if int(floor((x - map_origin.x) / TILE_SIZE)) % MAJOR_LINE_EVERY == 0:
				color = grid_color_major
			grid_start = Vector2(x, start_y)
			grid_end   = Vector2(x, end_y)
			draw_line(grid_start, grid_end, color, grid_halfwidth)

		# Horizontal lines
		for y in range(int(start_y), int(end_y) + 1, int(TILE_SIZE)):
			var color: Color = grid_color_minor
			if int(floor((y - map_origin.y) / TILE_SIZE)) % MAJOR_LINE_EVERY == 0:
				color = grid_color_major
			grid_start = Vector2(start_x, y)
			grid_end   = Vector2(end_x, y)
			draw_line(grid_start, grid_end, color, grid_halfwidth)
			
			
func _input(event: InputEvent) -> void: 
	# Toggle grid visibility with fade
	if event.is_action_pressed("toggle_grid"):
		grid_state = !grid_state
		if grid_state:
			fade_in_grid()
		else:
			fade_out_grid()

#fade out coroutine (await can't be used in _input) 
func fade_out_grid() -> void:
	await get_tree().process_frame
	while grid_color_major.a > 0.01:
		grid_color_major.a *= 0.90
		grid_color_minor.a *= 0.90
		queue_redraw()
		await get_tree().process_frame

#fade in coroutine (await can't be used in _input) 
func fade_in_grid() -> void:
	await get_tree().process_frame
	while grid_color_major.a < 0.49:
		grid_color_major.a *= 1.05
		grid_color_minor.a *= 1.05
		queue_redraw()
		await get_tree().process_frame
