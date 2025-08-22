extends Node

# BuildCatalogue.gd
# -----------------
# Central registry of all buildable tile definitions, organised by layer and source name.
# Provides lookup helpers so other systems can fetch tile data (IDs, atlas coords, costs, etc.).
# Keeps layer mirrors (e.g. StructuresLayer, GhostLayer) in sync with StructuresLayer definitions.

# Global definition index: [layer_name][source_name] -> definition dictionary
var catalogue: Dictionary = {}
var debug_switch : bool = true

func _ready() -> void:
	_build_catalogue()

func _build_catalogue() -> void:
	# NOTE: Update these resource paths to your real paths; placeholders shown here.
	var structures_layer := {
		"StoneTile": {
			"display_name": "StoneTile",
			"source_id": 0,
			"source_name": "StoneTile",
			"tileset_path": "res://tilesets/structures.tres",
			"tiles": {"StoneTile": Vector2i(2, 2)},
			"priority": 1,
			"cost": {"stone": 1}
		},
		"Medusa": {
			"display_name": "Medusa",
			"source_id": 1,
			"source_name": "Medusa",
			"tileset_path": "res://StructureManager/data/structures.tres",
			"tiles": {"MedusaTile": Vector2i(3, 7)},
			"priority": 2,
			"cost": {"stone": 2}
		}
	}

	catalogue = {
		"StructuresLayer": structures_layer,
		# Mirrors for overlays; fine for now, easy to change later.
		"EraseOverlayLayer": structures_layer.duplicate(true),
		"GhostLayer": structures_layer.duplicate(true),

		# TODO will need to pick the correct atlas coords
		# Terrain examples (expand as needed)
		"GroundLayer": {
			"Grass": {
				"display_name": "Grass",
				"source_id": 0,
				"source_name": "Grass",
				"tileset_path": "res://tilesets/ground.tres",
				"tiles": {},
				"priority": 0,
				"cost": {}
			}
		},

		# TODO will need to pick the correct atlas coords
		"WaterLayer": {
			"Water": {
				"display_name": "Water",
				"source_id": 0,
				"source_name": "Water",
				"tileset_path": "res://tilesets/water.tres",
				"tiles": {"WaterTile": Vector2i(4, 7)},
				"priority": 0,
				"cost": {}
			}
		}
	}

# ---------- Lookup helpers ----------
#get tile dictionary e.g. get_tile("StructuresLayer", "Stone")
func get_tile(layer: String, source: String) -> Dictionary:
	var tiles: Dictionary =  catalogue.get(layer, {}).get(source, {})
	if debug_switch:
		print("[BuildCatalog] ", tiles)
	return tiles
