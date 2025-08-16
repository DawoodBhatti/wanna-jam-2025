extends RefCounted
class_name EffectContext

# ============================================================================
# Purpose:
#   Centralises game references and helper methods for effects.
#   Supports both fast-path direct layer references and dynamic name lookups
#   based on your "BaseGrid" + sibling "Tiles" hierarchy.
# ============================================================================

# Core refs
var game_state: GameState
var resources: Node
var base_grid: Node2D                  # Points to "BaseGrid" node in scene

# Fast path: direct handles
var grid_layer: TileMapLayer
var erase_overlay_layer: TileMapLayer
var ghost_layer: TileMapLayer
var structures_layer: TileMapLayer
var ground_layer: TileMapLayer
var water_layer: TileMapLayer

# --------------------------------------------------------------------------
# NEIGHBOUR HELPERS
# --------------------------------------------------------------------------
func neighbors_4(p: Vector2i) -> Array[Vector2i]:
	return [p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.DOWN, p + Vector2i.UP]

func neighbors_8(p: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			out.append(p + Vector2i(dx, dy))
	return out

# --------------------------------------------------------------------------
# QUERIES & MUTATIONS (fast path)
# --------------------------------------------------------------------------
func has_structure_at(p: Vector2i) -> bool:
	return structures_layer and structures_layer.get_cell_tile_data(p) != null

func erase_at(p: Vector2i, layer: TileMapLayer = structures_layer) -> void:
	if layer:
		layer.set_cell(p, -1, Vector2i.ZERO)

# --------------------------------------------------------------------------
# LOOKUP HELPERS (dynamic path)
# --------------------------------------------------------------------------
func _resolve_tilemap_layer(layer_name: String) -> TileMapLayer:
	# Go up to parent, then across to sibling "Tiles"
	var tiles_node := base_grid.get_node_or_null("../Tiles")
	if tiles_node == null:
		push_error("[EffectContext] No 'Tiles' node found relative to base_grid")
		return null

	for child in tiles_node.get_children():
		if child is TileMapLayer and child.name == layer_name:
			return child as TileMapLayer
	
	push_error("[EffectContext] Layer '%s' not found under '../Tiles'" % layer_name)
	return null

# --------------------------------------------------------------------------
# GENERIC SET CELL
# --------------------------------------------------------------------------
func set_cell(p: Vector2i, source_id: int, atlas: Vector2i, layer) -> void:
	var target_layer: TileMapLayer = null

	if typeof(layer) == TYPE_STRING:
		target_layer = _resolve_tilemap_layer(layer)
	elif layer is TileMapLayer:
		target_layer = layer
	else:
		push_error("[EffectContext] Invalid layer identifier: %s" % str(layer))
		return

	if target_layer:
		print("[EffectContext] Setting cell at ", p, " src=", source_id, " atlas=", atlas, " on ", target_layer.get_path())
		target_layer.set_cell(p, source_id, atlas)

# --------------------------------------------------------------------------
# CATALOG‑DRIVEN SET CELL
# --------------------------------------------------------------------------
func set_cell_by_name(p: Vector2i, layer_name: String, source_name: String, tile_name: String) -> void:
	var source_dict: Dictionary = Catalog.catalog.get(layer_name, {}).get(source_name, {})
	if source_dict.is_empty():
		push_error("[EffectContext] Catalog entry not found for %s/%s" % [source_name, tile_name])
		return
	
	var sid: int = int(source_dict.get("source_id", -1))
	var atlas: Vector2i = Vector2i(source_dict.get("tiles", {}).get(tile_name, Vector2i(-1, -1)))
	if sid < 0 or atlas == Vector2i(-1, -1):
		push_error("[EffectContext] Invalid tile coords for %s/%s" % [source_name, tile_name])
		return
	
	set_cell(p, sid, atlas, layer_name)
