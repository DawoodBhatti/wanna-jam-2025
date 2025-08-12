extends Node2D

@onready var structures_layer: TileMapLayer = %StructuresLayer
@onready var ghost_layer: TileMapLayer = %GhostLayer

var tile_selected := false

# The tile to place
var source_id: int
var atlas_coords: Vector2i

# Drag state
var is_placing := false
var is_erasing := false
var last_place_pos := Vector2i(1_000_000, 1_000_000)
var last_erase_pos := Vector2i(1_000_000, 1_000_000)


func _ready():
	# Optional: sanity check
	if ghost_layer == null:
		push_warning("GhostLayer not assigned...")


func _input(event):
	# Toggle select mode with key '1'
	if event.is_action_pressed("select_tile_1"):
		tile_selected = !tile_selected
		print("stone tile selected:", tile_selected)
		source_id = 0
		atlas_coords = Vector2i(8, 2)

		# Show/hide the ghost layer (guard null)
		if ghost_layer:
			ghost_layer.visible = tile_selected
			if not tile_selected:
				ghost_layer.clear()

	# Mouse button presses/releases
	if event is InputEventMouseButton:
		# LEFT: start/stop painting
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_placing = true
				_place_at_mouse() # place immediately on click
			else:
				is_placing = false
				last_place_pos = Vector2i(1_000_000, 1_000_000) # reset dedupe

		# RIGHT: start/stop erasing (optional drag erase)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_erasing = true
				_erase_at_mouse() # erase immediately on click
			else:
				is_erasing = false
				last_erase_pos = Vector2i(1_000_000, 1_000_000) # reset dedupe

	# While moving the mouse, continue action if held, and update ghost
	if event is InputEventMouseMotion:
		if is_placing:
			_place_at_mouse()
		if is_erasing:
			_erase_at_mouse()
		if tile_selected:
			_update_ghost()


func _process(_delta):
	# Keep ghost responsive even if no mouse motion
	if tile_selected:
		_update_ghost()


# here we convert the global mouse position to a grid position 
func _get_tile_pos_under_mouse() -> Vector2i:
	var mouse_global := get_global_mouse_position()
	var local_pos := structures_layer.to_local(mouse_global)
	return structures_layer.local_to_map(local_pos)


func _place_at_mouse():
	if not tile_selected:
		return
	var tile_pos := _get_tile_pos_under_mouse()
	if tile_pos == last_place_pos:
		return

	# Optional: Fill gaps if the cursor jumped more than 1 cell this event.
	# _paint_line(last_place_pos, tile_pos)

	structures_layer.set_cell(tile_pos, source_id, atlas_coords)
	last_place_pos = tile_pos


func _erase_at_mouse():
	var tile_pos := _get_tile_pos_under_mouse()
	if tile_pos == last_erase_pos:
		return
	var tile_data := structures_layer.get_cell_tile_data(tile_pos)
	if tile_data != null:
		structures_layer.erase_cell(tile_pos)
	last_erase_pos = tile_pos


func _update_ghost():
	if ghost_layer == null:
		return

	# Keep transforms and tileset aligned in case the layer moved or changed
	if ghost_layer.transform != structures_layer.transform:
		ghost_layer.transform = structures_layer.transform
	if ghost_layer.tile_set != structures_layer.tile_set:
		ghost_layer.tile_set = structures_layer.tile_set

	var tile_pos := _get_tile_pos_under_mouse()
	ghost_layer.clear()
	ghost_layer.set_cell(tile_pos, source_id, atlas_coords)


# Simple integer line painter to avoid gaps while dragging fast.
# Calls set_cell on every stepped tile between a and b (inclusive).
func _paint_line(a: Vector2i, b: Vector2i) -> void:
	if a.x == 1_000_000: # guard for first placement when last_place_pos is "reset"
		return
	var dx := b.x - a.x
	var dy := b.y - a.y
	var steps := maxi(abs(dx), abs(dy))
	if steps == 0:
		return
	var sx := float(dx) / float(steps)
	var sy := float(dy) / float(steps)
	var fx := float(a.x)
	var fy := float(a.y)
	for i in range(steps + 1):
		var p := Vector2i(roundi(fx), roundi(fy))
		structures_layer.set_cell(p, source_id, atlas_coords)
		fx += sx
		fy += sy
