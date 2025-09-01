extends Node

# -------------------------------------------------------------------
# 🗂 Tile schema for reference / documentation
# -------------------------------------------------------------------
const TILE_SCHEMA: Dictionary = {
	"tile_name": #this is the key
		
		{ #and this is the value which is a nested dictionary
		"source_id": "Atlas ID in TileSet",
		"level_layer": "layer(s) this tile can be built upon",
		"tileset_path": "location to the tileset resource",
		"atlas_coords": "vector co-ordinates in the Atlas e.g. Vector2i(1,2)",
		"tile_name": "self contained tile's name",
		"trackable": "true / false if you want to add this to structure_state.gd for further control"
	}
}

#TODO we could introduce things like priority and cost into the schema
#if we require them...

# Global definition index: [tile_name] -> definition dictionary
var catalogue: Dictionary = {}


# Create our tile catalogue and init TileState with empty entries for all possible tiles
func _ready() -> void:
	_tile_catalogue()


func _tile_catalogue() -> void:
	var new_catalogue: Dictionary = {}

	new_catalogue["StoneTile"] = {
		"source_id": 0 as int,
		"build_layer": "StructuresLayer" as String,
		"tileset_path": "res://tilesets/structures.tres" as String,
		"tiles": [Vector2i(2, 2)] as Array,
		"tile_name": "StoneTile",
		"trackable": true
	}

	#TODO: get working sometime.
	new_catalogue["MedusaTile"] = {
		"source_id": 1 as int,
		"build_layer": "StructuresLayer" as String,
		"tileset_path": "res://StructureManager/data/structures.tres" as String,
		"tiles": [Vector2i(3, 7)] as Array,
		"tile_name": "MedusaTile",
		"trackable": true
	}

	new_catalogue["GrassTile"] = {
		"source_id": 0 as int,
		"build_layer": "GroundLayer" as String,
		"tileset_path": "res://tilesets/ground.tres" as String,
		"tiles": [Vector2i(0, 0)] as Array,
		"tile_name": "GrassTile",
		"trackable": false
			}

	new_catalogue["WaterTile"] = {
		"source_id": 0 as int,
		"build_layer": "WaterLayer" as String,
		"tileset_path": "res://tilesets/water.tres" as String,
		"tiles": [Vector2i(4, 7)] as Array,
		"tile_name": "WaterTile",
		"trackable": false
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
