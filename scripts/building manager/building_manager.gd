# building_manager.gd
# Orchestrates building actions. The only public API for placement, painting, and removal.

# =============================================================================
# BUILDING SYSTEM – QUICK REFERENCE
# =============================================================================
# building_manager.gd     – Orchestrates build mode; starts/stops PlacementAction or RemovalAction.
# IBuildAction.gd         – Base interface for all build actions; defines start(), process_input(), and stop() lifecycle methods.

# build_catalogue.gd      – Central registry of all buildable definitions; helper methods included.

# placement.gd            – Handles building placement; caches build data once; calls PlacementService.
# placement_service.gd    – Core placement/preview logic; validates via PlacementRules; updates Level layers; emits placement signals.
# placement_rules.gd      – Validates if a building can be placed at a given cell (terrain, collisions, resources, etc.).

# removal.gd              – Handles building removal; calls RemovalService.
# removal_service.gd      – Core removal/preview logic; validates via RemovalRules; updates Level layers; emits removal signals.
# removal_rules.gd        – Validates if a building/tile can be removed from a given cell (ownership, dependencies, etc.).

# =============================================================================
extends Node

@onready var _placement = $Placement
@onready var _removal = $Removal

#TODO: add in logic for cards to place enter these modes too

var _current_action: IBuildAction = null


func placement(building_name: String, limit := 0):
	_current_action = _placement
	_current_action.start({"building_name": building_name, "limit": limit})


func removal(target_type: String, limit := 0):
	_current_action = _removal
	_current_action.start({"target_type": target_type, "limit": limit})

func stop():
	if _current_action:
		_current_action.stop()
	_current_action = null

func _input(event):
	if _current_action:
		_current_action.process_input(event)
