# StructureSpecs.gd
extends RefCounted
class_name StructureSpecs

# Template for a structure type; instances of this are attached to placed records.
var id: String
var display_name: String
var layer: String
var source_id: int
var source_name: String
var tileset_path: String
var tiles: Dictionary = {	}      # e.g. {"StoneTile": Vector2i(8, 2)}
var priority: int = 0
var cost: Dictionary = {}       # e.g. {"stone": 1, "wood": 2}
var tags: Array[String] = []    # optional categorisation tags

# Hook for end‑turn behaviour if/when you add it.
func apply(ctx: Variant, pos: Vector2i) -> void:
	# Intentionally no default behaviour; manager or effect system decides when to call.
	pass
