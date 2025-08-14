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

# ---- Placement data (TileSet-side) ----
var source_id: int = 0
var atlas_coords: Vector2i = Vector2i.ZERO

# ---- Placement context (Catalog-side; used for emission and clarity) ----
var ctx_layer_name: String = ""         # e.g., "StructuresLayer"
var ctx_source_name: String = ""        # e.g., "Stone" (Catalog key)
var ctx_tile_name: String = ""          # e.g., "StoneTile" (Catalog tile key)
var ctx_display_name: String = ""       # e.g., "Stone Wall" (friendly)

# ---- Budgets (0 = unlimited) ----
var place_budget: int = 0
var erase_budget: int = 0

# ---- Drag state ----
const FIRST_SENTINEL := Vector2i(1_000_000, 1_000_000)
var dragging: bool = false
var last_mouse_tile: Vector2i = FIRST_SENTINEL

# ---- Cache (per-frame) ----
var _cached_mouse_tile: Vector2i = FIRST_SENTINEL

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

	debug_print_tiles_children_and_tilesets()

# -----------------
# External API (card play / manager / debug)
# -----------------
func enter_place_mode(data: Dictionary, amount: int = 1) -> void:
	# Expected flexible inputs (any subset is fine):
	# - Names path (preferred): "layer", "source_name", "tile_name"
	# - Or raw ids: "source_id", "atlas_coords"
	# We resolve to both TileSet ids and Catalog names here and cache them.
	mode = MODE_PLACE
	place_budget = max(amount, 0)  # 0 = unlimited
	erase_budget = 0

	# Default layer to actual placement layer name if not provided
	var layer_name: String = data.get("layer", structures_layer.name)

	var resolved := _resolve_place_context_from_data(layer_name, data)
	if not resolved:
		push_error("[BaseGrid] enter_place_mode: could not resolve placement from data=" + str(data))
		clear_modes()
		return

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
		# Example: select from Catalog by names (preferred path)
		var data := {
			"layer": "StructuresLayer",
			"source_name": "Stone",
			"tile_name": "StoneTile"
		}
		enter_place_mode(data, 0)  # 0 = unlimited

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
	if last_mouse_tile == FIRST_SENTINEL:
		_apply_single(tile_now)
	else:
		_apply_line(last_mouse_tile, tile_now)
	last_mouse_tile = tile_now

func _apply_single(tile_pos: Vector2i) -> void:
	match mode:
		MODE_PLACE:
			if _consume_place(1) > 0:
				structures_layer.set_cell(tile_pos, source_id, atlas_coords)

				# Emit with full Catalog-backed context (no TileSet queries needed)
				emit_signal("structure_tile_placed", {
					"layer": ctx_layer_name,
					"source_name": ctx_source_name,
					"tile_name": ctx_tile_name,
					"display_name": ctx_display_name,
					"pos": tile_pos,
					"source_id": source_id,
					"atlas_coords": atlas_coords
				})

				_check_complete()

		MODE_REMOVE:
			# Only erase if there's something to remove
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

	for _i in range(steps + 1): # inclusive, paints both a and b
		var p := Vector2i(roundi(fx), roundi(fy))
		_apply_single(p)
		if mode == MODE_NONE:
			break
		fx += sx
		fy += sy

# -----------------
# Budget helpers
# -----------------
func _consume_place(request: int) -> int:
	if place_budget == 0:
		return request  # unlimited
	var granted: int = min(place_budget, request)
	place_budget -= granted
	return granted

func _consume_erase(request: int) -> int:
	if erase_budget == 0:
		return request  # unlimited
	var granted: int = min(erase_budget, request)
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
	last_mouse_tile = FIRST_SENTINEL

# -----------------
# Catalog resolution
# -----------------
func _resolve_place_context_from_data(layer_name: String, data: Dictionary) -> bool:
	# Preferred: names path
	print("[PlaceResolve]",
	" layer=", ctx_layer_name,
	" source=", ctx_source_name,
	" tile=", ctx_tile_name,
	" src_id=", source_id,
	" atlas=", atlas_coords
)
	
	if data.has("source_name") and data.has("tile_name"):
		return _resolve_from_catalog_names(layer_name, String(data.source_name), String(data.tile_name))

	# Fallback: raw ids -> reverse lookup via Catalog
	var has_ids := data.has("source_id") and data.has("atlas_coords")
	if has_ids:
		return _resolve_from_ids_via_catalog(layer_name, int(data.source_id), Vector2i(data.atlas_coords))

	# Nothing usable
	return false

func _resolve_from_catalog_names(layer_name: String, source_name: String, tile_name: String) -> bool:
	var layer_dict: Dictionary = Catalog.catalog.get(layer_name, {})
	if layer_dict.is_empty():
		return false

	var source_dict: Dictionary = layer_dict.get(source_name, {})
	if source_dict.is_empty():
		return false

	var tiles_dict: Dictionary = source_dict.get("tiles", {})
	if not tiles_dict.has(tile_name):
		return false

	# Populate both TileSet ids and Catalog context
	source_id = int(source_dict.get("source_id", -1))
	atlas_coords = Vector2i(tiles_dict.get(tile_name, Vector2i(-1, -1)))

	if source_id < 0 or atlas_coords == Vector2i(-1, -1):
		return false

	ctx_layer_name = layer_name
	ctx_source_name = source_name
	ctx_tile_name = tile_name
	ctx_display_name = String(source_dict.get("display_name", source_name))
	return true

func _resolve_from_ids_via_catalog(layer_name: String, src_id: int, coords: Vector2i) -> bool:
	var layer_dict: Dictionary = Catalog.catalog.get(layer_name, {})
	if layer_dict.is_empty():
		return false

	# Find the source with matching source_id
	var found_source_name := ""
	var found_source_dict: Dictionary = {}
	for s_name in layer_dict.keys():
		var sd: Dictionary = layer_dict[s_name]
		if int(sd.get("source_id", -9999)) == src_id:
			found_source_name = String(s_name)
			found_source_dict = sd
			break

	if found_source_name == "":
		return false

	# Find the tile key with matching coords
	var tiles_dict: Dictionary = found_source_dict.get("tiles", {})
	var found_tile_name := ""
	for t_name in tiles_dict.keys():
		if Vector2i(tiles_dict[t_name]) == coords:
			found_tile_name = String(t_name)
			break

	if found_tile_name == "":
		# We still allow placement but can't name the tile precisely
		found_tile_name = ""  # keep empty; display_name still useful

	# Populate both TileSet ids and Catalog context
	source_id = src_id
	atlas_coords = coords

	ctx_layer_name = layer_name
	ctx_source_name = found_source_name
	ctx_tile_name = found_tile_name
	ctx_display_name = String(found_source_dict.get("display_name", found_source_name))
	return true

# -----------------
# Debug
# -----------------
func debug_print_tiles_children_and_tilesets() -> void:
	print("Children and TileSet info for this node:")
	for child: Node in get_children():
		print("- ", child.name)
		if child is TileMapLayer:
			var tile_map_layer: TileMapLayer = child
			var tile_set: TileSet = tile_map_layer.tile_set
			if tile_set != null:
				var path: String = tile_set.resource_path
				if path != "":
					print("    TileSet Path:", path)
				else:
					print("    TileSet is built-in or unsaved")

				var source_count: int = tile_set.get_source_count()
				print("    Source Count:", source_count)

				for i in range(source_count):
					var s_id: int = tile_set.get_source_id(i)
					var source: TileSetSource = tile_set.get_source(s_id)
					var source_type: String = source.get_class()
					print("      Source Index:", i, " Source ID:", s_id, " Type:", source_type, " Name:", source.resource_name)
			else:
				print("    (No TileSet assigned)")
