# PlacementRules.gd
# Centralised placement validation logic.
# All actions call this before committing a tile.

extends Node
class_name PlacementRules

@onready var _level = get_node("../../Level")

func is_valid(cell_pos: Vector2i, building_name: String) -> bool:
	# TODO: can add real logic here. for example stone can only be built on tiles with grass and no other structures
	
	return true
