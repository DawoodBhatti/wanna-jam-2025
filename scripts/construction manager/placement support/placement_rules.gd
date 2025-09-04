# PlacementRules.gd
# Centralised placement validation logic.
# All actions call this before committing a tile.

extends Node
class_name PlacementRules


func is_valid(_cell_pos: Vector2i, _building_name: String) -> bool:
	# TODO: can add real logic here. for example stone can only be built on tiles with grass and no other structures
	
	return true
