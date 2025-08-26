# BuildingManager.gd
# Orchestrates building actions. The only public API for placement, painting, and removal.

# =============================================================================
# BUILDING SYSTEM – QUICK REFERENCE
# =============================================================================
# building_manager.gd       – Orchestrates build mode; starts/stops PlacementAction or PaintingAction.
# IBuildAction.gd       – Base interface for all build actions; defines start(), process_input(), and stop() lifecycle methods.
# placement_action.gd    – Handles single‑click placement; caches build data; calls PlacementService.
# painting_action.gd     – Handles multiple-click (paint) placement; caches build data once; calls PlacementService.
# removal_action.gd      – Handles erasing/removing placed tiles; updates layers and emits removal signals.
# placement_service.gd   – Core placement/preview logic; validates via PlacementRules; updates Level layers; emits signals.
# placement_rules.gd     – Validates if a building can be placed at a given cell (terrain, collisions, resources, etc.).
# build_catalogue.gd     – Central registry of all buildable definitions; get_tile(layer, source) returns a definition.
# =============================================================================

extends Node

@onready var _place_single = $PlaceSingle
@onready var _place_multiple = $PlaceMultiple
@onready var _remove_single = $RemoveSingle
@onready var _remove_multiple = $RemoveMultiple

#TODO: add in logic for cards to place enter painting mode, too

var _current_action: IBuildAction = null

func place_single(building_name: String):
	_current_action = _place_single
	_current_action.start({"building_name": building_name})

func place_multiple(building_name: String, limit := 0):
	_current_action = _place_multiple
	_current_action.start({"building_name": building_name, "limit": limit})

func remove_single(target_type: String):
	_current_action = _remove_single
	_current_action.start({"target_type": target_type})

func remove_multiple(target_type: String, limit := 0):
	_current_action = _remove_multiple
	_current_action.start({"target_type": target_type, "limit": limit})

func stop():
	if _current_action:
		_current_action.stop()
	_current_action = null

func _input(event):
	if _current_action:
		_current_action.process_input(event)
