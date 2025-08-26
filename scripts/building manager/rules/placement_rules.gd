# PlacementRules.gd
# Centralised placement validation logic.
# All actions call this before committing a tile.

extends Node
class_name PlacementRules

@onready var _level = get_node("../../Level")

func is_valid(cell_pos: Vector2i, building_name: String) -> bool:
	# TODO: Add real logic here (terrain checks, collisions, adjacency, etc.)
	# For now, always returns true.
	
	print("some resource checks to be added?")
	
	return true
