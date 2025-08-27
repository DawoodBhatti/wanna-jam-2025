extends Node

# -------------------------------------------------------------------
# 🗂 Build schema for reference / documentation
# -------------------------------------------------------------------
const BUILD_SCHEMA: Dictionary = {
	"building_name": {
		"source_id": "Atlas ID in TileSet",
		"build_layer": "layer(s) this tile can be built upon",
		"tileset_path": "location to the tileset resource",
		"tiles": "vector co-ordinates in the Atlas e.g. Vector2i(1,2)"
	}
}

# Global definition index: [tile_name] -> definition dictionary
var catalogue: Dictionary = {}

func _ready() -> void:
	_build_catalogue()

func _build_catalogue() -> void:
	var new_catalogue: Dictionary = {}

	new_catalogue["StoneTile"] = {
		"source_id": 0 as int,
		"build_layer": "StructuresLayer" as String,
		"tileset_path": "res://tilesets/structures.tres" as String,
		"tiles": [Vector2i(2, 2)] as Array,
		"cost": {"stone": 1} as Dictionary
	}

	#TODO: get working sometime.
	new_catalogue["MedusaBuilding"] = {
		"source_id": 1 as int,
		"build_layer": "StructuresLayer" as String,
		"tileset_path": "res://StructureManager/data/structures.tres" as String,
		"tiles": [Vector2i(3, 7)] as Array,
		"cost": {"stone": 2} as Dictionary
	}

	new_catalogue["Grass"] = {
		"source_id": 0 as int,
		"build_layer": "GroundLayer" as String,
		"tileset_path": "res://tilesets/ground.tres" as String,
		"tiles": [Vector2i(0, 0)] as Array,
		"priority": 0 as int,
		"cost": {} as Dictionary
	}

	new_catalogue["WaterTile"] = {
		"source_id": 0 as int,
		"build_layer": "WaterLayer" as String,
		"tileset_path": "res://tilesets/water.tres" as String,
		"tiles": [Vector2i(4, 7)] as Array,
		"priority": 0 as int,
		"cost": {} as Dictionary
	}

	catalogue = new_catalogue

# ---------- Lookup helpers ----------

func get_tile(type_name: String) -> Dictionary:
	return catalogue.get(type_name, {}) as Dictionary

func is_tile_type(layer: TileMapLayer, cell: Vector2i, type_name: String) -> bool:
	var def: Dictionary = get_tile(type_name)
	if def.is_empty():
		return false

	var src_id: int = layer.get_cell_source_id(cell)
	var coords: Vector2i = layer.get_cell_atlas_coords(cell)
	var alt: int = layer.get_cell_alternative_tile(cell)
	var def_coords: Vector2i = def["tiles"][0] as Vector2i if def["tiles"].size() > 0 else Vector2i(-1, -1)

	return src_id == def["source_id"] and coords == def_coords and alt == 0
