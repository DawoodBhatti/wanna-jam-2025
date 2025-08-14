class_name TileCatalog
extends Node

var catalog: Dictionary = {}
var x: int = 0
var y: int = 0

func _ready() -> void:
	_build_catalog()

func _build_catalog() -> void:
	# elements in catalog correspond to:
	# the TileSetLayer we have included
	# the name of the tileset(s)
	# the source id of the tileset(s)
	# path to the resource (probably overkill)
	# the vector co-ordinates of specific tiles within the atlas.

	var structures_layer: Dictionary = {
		"Stone": {
			"source_id": 0,
			"source_name": "Stone",
			"tileset_path": "res://scenes + scripts/StructureManager/data/structures.tres",
			"tiles": {
				"StoneTile": Vector2i(8, 2)  
			}
		},
		"Medusa": {
			"source_id": 1,
			"source_name": "Medusa",
			"tileset_path": "res://scenes + scripts/StructureManager/data/structures.tres",
			"tiles": {
				"MedusaTile": Vector2i(3, 7) 
			}
		}
	}

	catalog = {
		#the erasure layer and the ghost layer just copy whatever is in the structures layer so...
		"StructuresLayer": structures_layer,
		"EraseOverlayLayer": structures_layer.duplicate(true),
		"GhostLayer": structures_layer.duplicate(true),
		"GroundLayer": {
			"Grass": {
				"source_id": 0,
				"source_name": "Grass",
				"tileset_path": "res://scenes + scripts/Tiles/basegrid.tscn::TileSet_cjpsi",
				"tiles": {
					# TODO will define!
				}
			}
		},
		"WaterLayer": {
			"Water": {
				"source_id": 0,
				"source_name": "Water",
				"tileset_path": "res://scenes + scripts/Tiles/basegrid.tscn::TileSet_g0cmg",
				"tiles": {
					"WaterTile": Vector2i(4, 7)  # TODO will define!
				}
			}
		}
	}
