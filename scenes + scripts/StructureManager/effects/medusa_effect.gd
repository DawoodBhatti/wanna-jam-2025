extends RefCounted
class_name TilePlacingEffect
"""
Base for effects that place tiles into a target layer.
Default config is Medusa (petrify): finds the tile by its Catalog names.
"""

# --- Defaults: Medusa ---
const TILE_VALUE: String = "MedusaTile"           # Catalog tile name
const TARGET_LAYER: String = "StructuresLayer"    # Where to place the tile
const SOURCE_NAME: String = "Medusa"              # Catalog source name
const ALLOWED_NAMES: Array[String] = ["Ground"]   # Ground-layer tile names allowed to overwrite
const GROUND_LAYER: String = "GroundLayer"

func apply_effect(ctx: EffectContext, pos: Vector2i) -> void:
	print("\n[%s] apply_effect at %s" % [TILE_VALUE, pos])

	var ground_layer: TileMapLayer = ctx._resolve_tilemap_layer(GROUND_LAYER)
	if not ground_layer:
		push_error("[%s] Ground layer '%s' missing" % [TILE_VALUE, GROUND_LAYER])
		return

	for n: Vector2i in ctx.neighbors_8(pos):
		# Skip empty ground or existing structure
		if ground_layer.get_cell_tile_data(n) == null:
			continue
		if ctx.has_structure_at(n):
			continue
		if not _is_allowed_on_ground(ground_layer, n):
			continue

		# Catalog-driven placement — no hardcoded IDs
		ctx.set_cell_by_name(n, TARGET_LAYER, SOURCE_NAME, TILE_VALUE)

func _is_allowed_on_ground(ground_layer: TileMapLayer, pos: Vector2i) -> bool:
	if ALLOWED_NAMES.is_empty():
		return true
	var td: TileData = ground_layer.get_cell_tile_data(pos)
	if td == null:
		return false
	return td.get_tile_name() in ALLOWED_NAMES
