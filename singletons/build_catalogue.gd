# BuildCatalogue.gd
extends Node

# Global definition index: [layer_name][source_name] -> definition dictionary
var catalogue: Dictionary = {}

func _ready() -> void:
	_build_catalogue()

func _build_catalogue() -> void:
	# NOTE: Update these resource paths to your real paths; placeholders shown here.
	var structures_layer := {
		"Stone": {
			"display_name": "Stone",
			"source_id": 0,
			"source_name": "Stone",
			"tileset_path": "res://tilesets/structures.tres",
			"tiles": {"StoneTile": Vector2i(8, 2)},
			"priority": 1,
			"cost": {"stone": 1}
		},
		#TODO will need to put this back in, yeah?
		#"Medusa": {
			#"display_name": "Medusa",
			#"source_id": 1,
			#"source_name": "Medusa",
			#"tileset_path": "res://StructureManager/data/structures.tres",
			#"tiles": {"MedusaTile": Vector2i(3, 7)},
			#"priority": 2,
			#"cost": {"stone": 2}
		#}
	}

	catalogue = {
		"StructuresLayer": structures_layer,
		# Mirrors for overlays; fine for now, easy to change later.
		"EraseOverlayLayer": structures_layer.duplicate(true),
		"GhostLayer": structures_layer.duplicate(true),

		#TODO will need to pick the correct atlas coords
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

		#TODO will need to pick the correct atlas coords
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
func get_spec_data(layer: String, source: String) -> Dictionary:
	return catalogue.get(layer, {}).get(source, {})

func has_spec(layer: String, source: String) -> bool:
	return not get_spec_data(layer, source).is_empty()

func list_layers() -> Array:
	return catalogue.keys()

func list_sources(layer: String) -> Array:
	return catalogue.get(layer, {}).keys()
