extends Node2D

# ---- Signals ----
signal structure_tile_placed(tile_info: Dictionary)   # fired on build‑card placement
signal structure_tile_erased(tile_info: Dictionary)   # fired on recycle‑card erase

# ---- Layers ----
@onready var structures_layer: TileMapLayer = %StructuresLayer
@onready var ghost_layer: TileMapLayer = %GhostLayer

# ---- Modes ----
var tile_selected: bool = false         # generic select flag (debug + structure mode)
var in_structure_mode: bool = false     # true if waiting for one‑shot structure placement
var in_recycle_mode: bool = false       # true if waiting for one‑shot recycle click

# ---- Placement data ----
var source_id: int = 0
var atlas_coords: Vector2i = Vector2i.ZERO

# ---- Drag state ----
var is_placing: bool = false
var is_erasing: bool = false
var last_place_pos: Vector2i = Vector2i(1_000_000, 1_000_000)
var last_erase_pos: Vector2i = Vector2i(1_000_000, 1_000_000)

# -----------------
# Lifecycle
# -----------------
func _ready() -> void:
	if structures_layer == null:
		push_warning("StructuresLayer is null — check %StructuresLayer path.")
	if ghost_layer == null:
		push_warning("GhostLayer is null — check %GhostLayer path.")
	else:
		ghost_layer.visible = false
		ghost_layer.clear()

# -----------------
# External mode entry points (StructureManager calls these)
# -----------------
func enter_structure_mode(data: Dictionary) -> void:
	in_structure_mode = true
	in_recycle_mode = false
	tile_selected = true

	if data.has("source_id"):
		source_id = int(data.source_id)
	if data.has("atlas_coords"):
		atlas_coords = data.atlas_coords

	if ghost_layer:
		ghost_layer.visible = true
		ghost_layer.clear()

	last_place_pos = Vector2i(1_000_000, 1_000_000)

func enter_recycle_mode() -> void:
	in_recycle_mode = true
	in_structure_mode = false
	tile_selected = false
	if ghost_layer:
		ghost_layer.visible = false
		ghost_layer.clear()

# -----------------
# Input handling
# -----------------
func _input(event: InputEvent) -> void:
	# Manual toggle for debug (press 1)
	if event.is_action_pressed("select_tile_1"):
		tile_selected = not tile_selected
		print("stone tile selected:", tile_selected)
		source_id = 0
		atlas_coords = Vector2i(8, 2)
		if ghost_layer:
			ghost_layer.visible = tile_selected
			if not tile_selected:
				ghost_layer.clear()

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# LEFT: place
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_placing = true
				_place_at_mouse()
			else:
				is_placing = false
				last_place_pos = Vector2i(1_000_000, 1_000_000)
		# RIGHT: erase/recycle
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				is_erasing = true
				_erase_at_mouse()
			else:
				is_erasing = false
				last_erase_pos = Vector2i(1_000_000, 1_000_000)

	if event is InputEventMouseMotion:
		if is_placing:
			_place_at_mouse()
		if is_erasing:
			_erase_at_mouse()
		if tile_selected:
			_update_ghost()

func _process(_delta: float) -> void:
	if tile_selected:
		_update_ghost()

# -----------------
# Placement helpers
# -----------------
func _get_tile_pos_under_mouse() -> Vector2i:
	var mouse_global: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = structures_layer.to_local(mouse_global)
	return structures_layer.local_to_map(local_pos)

func _place_at_mouse() -> void:
	if in_recycle_mode:
		return # placing disabled in recycle mode
	if not tile_selected:
		return

	var tile_pos := _get_tile_pos_under_mouse()
	if tile_pos == last_place_pos:
		return

	structures_layer.set_cell(tile_pos, source_id, atlas_coords)
	last_place_pos = tile_pos

	# One‑shot structure mode → finish after first placement
	if in_structure_mode:
		in_structure_mode = false
		tile_selected = false
		if ghost_layer:
			ghost_layer.visible = false
			ghost_layer.clear()
		emit_signal("structure_tile_placed", {
			"pos": tile_pos,
			"source_id": source_id,
			"atlas_coords": atlas_coords
		})

func _erase_at_mouse() -> void:
	var tile_pos := _get_tile_pos_under_mouse()
	if tile_pos == last_erase_pos:
		return

	var tile_data := structures_layer.get_cell_tile_data(tile_pos)
	if tile_data != null:
		structures_layer.erase_cell(tile_pos)
		# One‑shot recycle mode → finish after first erase
		if in_recycle_mode:
			in_recycle_mode = false
			emit_signal("structure_tile_erased", { "pos": tile_pos })

	last_erase_pos = tile_pos

func _update_ghost() -> void:
	if ghost_layer == null:
		return
	if ghost_layer.transform != structures_layer.transform:
		ghost_layer.transform = structures_layer.transform
	if ghost_layer.tile_set != structures_layer.tile_set:
		ghost_layer.tile_set = structures_layer.tile_set

	var tile_pos := _get_tile_pos_under_mouse()
	ghost_layer.clear()
	ghost_layer.set_cell(tile_pos, source_id, atlas_coords)

# Optional: fill gaps if dragging quickly
func _paint_line(a: Vector2i, b: Vector2i) -> void:
	if a.x == 1_000_000:
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
