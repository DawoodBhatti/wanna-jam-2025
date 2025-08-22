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

@onready var _placement_action = $PlacementAction
@onready var _painting_action = $PaintingAction
@onready var _removal_action = $RemovalAction


#TODO: add removal painting into here
#TODO: add in logic for cards to place enter painting mode, too

var _current_action: IBuildAction = null

func place(building_name: String):
	_current_action = _placement_action
	_current_action.start({"building_name": building_name})

func paint(building_name: String, limit := 0):
	_current_action = _painting_action
	_current_action.start({"building_name": building_name, "limit": limit})

func remove():
	_current_action = _removal_action
	_current_action.start({})

func stop():
	if _current_action:
		_current_action.stop()
	_current_action = null

func _input(event):
	if _current_action:
		_current_action.process_input(event)
