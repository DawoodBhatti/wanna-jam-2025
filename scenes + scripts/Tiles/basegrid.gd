extends Node2D

# ---- Signals ----
signal structure_tile_placed(tile_info: Dictionary)   # emitted per placed tile
signal structure_tile_erased(tile_info: Dictionary)   # emitted per erased tile
signal place_mode_completed                           # emitted when place budget consumed
signal remove_mode_completed                          # emitted when remove budget consumed

# ---- Layers ----
@onready var structures_layer: TileMapLayer = %StructuresLayer
@onready var ghost_layer: TileMapLayer = %GhostLayer
@onready var erase_overlay_layer: TileMapLayer = %EraseOverlayLayer

# ---- Modes ----
const MODE_NONE := 0
const MODE_PLACE := 1
const MODE_REMOVE := 2
var mode: int = MODE_NONE

# ---- Placement data ----
var source_id: int = 0
var atlas_coords: Vector2i = Vector2i.ZERO

# ---- Budgets (0 = unlimited) ----
var place_budget: int = 0
var erase_budget: int = 0

# ---- Drag state ----
var dragging: bool = false
var last_mouse_tile: Vector2i = Vector2i(1_000_000, 1_000_000)

# ---- Cache (per-frame) ----
var _cached_mouse_tile: Vector2i = Vector2i(1_000_000, 1_000_000)

# -----------------
# Lifecycle
# -----------------
func _ready() -> void:
	if ghost_layer:
		ghost_layer.visible = false
		ghost_layer.clear()
	else:
		push_warning("GhostLayer missing")

	if erase_overlay_layer:
		erase_overlay_layer.visible = false
		erase_overlay_layer.clear()
		erase_overlay_layer.modulate = Color(1, 0, 0, 0.5)
	else:
		push_warning("EraseOverlayLayer missing")

# -----------------
# External API (card play / manager / debug)
# -----------------
func enter_place_mode(data: Dictionary, amount: int = 1) -> void:
	mode = MODE_PLACE
	place_budget = max(amount, 0)  # 0 = unlimited
	erase_budget = 0

	if data.has("source_id"):
		source_id = int(data.source_id)
	if data.has("atlas_coords"):
		atlas_coords = data.atlas_coords

	ghost_layer.visible = true
	erase_overlay_layer.visible = false
	_reset_drag()

func enter_remove_mode(amount: int = 1) -> void:
	mode = MODE_REMOVE
	erase_budget = max(amount, 0)
	place_budget = 0

	ghost_layer.visible = false
	erase_overlay_layer.visible = true
	_reset_drag()

func clear_modes() -> void:
	mode = MODE_NONE
	ghost_layer.visible = false
	erase_overlay_layer.visible = false
	_reset_drag()

# -----------------
# Input handling
# -----------------
func _input(event: InputEvent) -> void:
	# Debug toggles (optional)
	if event.is_action_pressed("select_tile_1"):
		enter_place_mode({"source_id": 0, "atlas_coords": Vector2i(8, 2)}, 0)  # 0 = unlimited for debug
	if event.is_action_pressed("remove_tile_1"):
		enter_remove_mode(0)

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mode != MODE_NONE:
					dragging = true
					_apply_at_mouse()
			else:
				dragging = false
				_reset_drag()

	if event is InputEventMouseMotion and dragging:
		_apply_at_mouse()

func _process(_delta: float) -> void:
	_refresh_previews()

# -----------------
# Core logic
# -----------------
func _apply_at_mouse() -> void:
	var tile_now := _get_mouse_tile_cached()
	if last_mouse_tile.x == 1_000_000:
		# First stroke: just act once at the current tile
		_apply_single(tile_now)
	else:
		# Bridge the path between last and current tile to avoid gaps
		_apply_line(last_mouse_tile, tile_now)
	last_mouse_tile = tile_now

func _apply_single(tile_pos: Vector2i) -> void:
	match mode:
		MODE_PLACE:
			if _consume_place(1) > 0:
				structures_layer.set_cell(tile_pos, source_id, atlas_coords)
				emit_signal("structure_tile_placed", {
					"pos": tile_pos,
					"source_id": source_id,
					"atlas_coords": atlas_coords
				})
				_check_complete()
		MODE_REMOVE:
			if structures_layer.get_cell_tile_data(tile_pos) != null:
				if _consume_erase(1) > 0:
					structures_layer.erase_cell(tile_pos)
					emit_signal("structure_tile_erased", {"pos": tile_pos})
					_check_complete()

func _apply_line(a: Vector2i, b: Vector2i) -> void:
	var dx := b.x - a.x
	var dy := b.y - a.y
	var steps := maxi(abs(dx), abs(dy))
	if steps <= 0:
		_apply_single(b)
		return

	var sx := float(dx) / float(steps)
	var sy := float(dy) / float(steps)
	var fx := float(a.x)
	var fy := float(a.y)

	for i in range(steps + 1):
		var p := Vector2i(roundi(fx), roundi(fy))
		# Skip exact duplicate consecutive tiles
		if i == 0 and p == a:
			# still apply at 'a' for correctness
			_apply_single(p)
		else:
			_apply_single(p)
		# Early out if mode finished
		if mode == MODE_NONE:
			break
		fx += sx
		fy += sy

func _consume_place(request: int) -> int:
	# Returns how many units granted (<= request)
	if place_budget == 0:
		return request  # unlimited
	var granted : int = min(place_budget, request)
	place_budget -= granted
	return granted

func _consume_erase(request: int) -> int:
	if erase_budget == 0:
		return request  # unlimited
	var granted : int = min(erase_budget, request)
	erase_budget -= granted
	return granted

func _check_complete() -> void:
	if mode == MODE_PLACE and place_budget == 0:
		clear_modes()
		emit_signal("place_mode_completed")
	elif mode == MODE_REMOVE and erase_budget == 0:
		clear_modes()
		emit_signal("remove_mode_completed")

# -----------------
# Previews
# -----------------
func _refresh_previews() -> void:
	match mode:
		MODE_PLACE:
			_update_ghost()
		MODE_REMOVE:
			_update_erase_overlay()

func _update_ghost() -> void:
	if not ghost_layer:
		return
	_align_layer(ghost_layer)
	var tile_pos := _get_mouse_tile_cached()
	ghost_layer.clear()
	ghost_layer.set_cell(tile_pos, source_id, atlas_coords)

func _update_erase_overlay() -> void:
	if not erase_overlay_layer:
		return
	_align_layer(erase_overlay_layer)
	var tile_pos := _get_mouse_tile_cached()
	erase_overlay_layer.clear()
	# Copy hovered tile (if any) and tint red
	var src_tile := structures_layer.get_cell_source_id(tile_pos)
	var src_atlas := structures_layer.get_cell_atlas_coords(tile_pos)
	if src_tile != -1:
		erase_overlay_layer.set_cell(tile_pos, src_tile, src_atlas)
	erase_overlay_layer.modulate = Color(1, 0, 0, 0.5)

# -----------------
# Helpers
# -----------------
func _align_layer(layer: TileMapLayer) -> void:
	if layer.transform != structures_layer.transform:
		layer.transform = structures_layer.transform
	if layer.tile_set != structures_layer.tile_set:
		layer.tile_set = structures_layer.tile_set

func _get_mouse_tile_cached() -> Vector2i:
	# Cache per frame to avoid repeated transforms
	var mouse_global: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = structures_layer.to_local(mouse_global)
	_cached_mouse_tile = structures_layer.local_to_map(local_pos)
	return _cached_mouse_tile

func _reset_drag() -> void:
	dragging = false
	last_mouse_tile = Vector2i(1_000_000, 1_000_000)
