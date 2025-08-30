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

# -------------------------------------------------------------------
# NODE REFERENCES
# -------------------------------------------------------------------
@onready var _placement = $Placement
@onready var _placement_square = $PlacementSquare
@onready var _removal = $Removal
@onready var _removal_square = $RemovalSquare
@onready var _level: Node = get_tree().get_root().get_node("Main/Level")

# -------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------
var _current_action: IBuildAction = null

# TODO: Add in logic for cards to enter these modes too


# ===================================================================
# 1. LIFECYCLE & STATE MANAGEMENT
# ===================================================================

## Stops the current build action (placement or removal) and clears reference.
func stop():
	if _current_action:
		_current_action.stop()
	_current_action = null

## Forwards all input events to the active build action.
func _input(event):
	if _current_action:
		_current_action.process_input(event)


# ===================================================================
# 2. INTERACTIVE BUILD ACTIONS
# ===================================================================

## Starts placement mode (interactive by default).
## - building_name: the tile/building to place
## - limit: max number of placements before auto-stop
## - auto_placement: if true, skips interactive input and places programmatically
## - placement_locations: array of Vector2i cells to place on (used in auto mode)
func placement(building_name: String, limit := 0, auto_placement := false, placement_locations: Array = []):
	_current_action = _placement
	_current_action.start({
		"building_name": building_name,
		"limit": limit,
		"auto_placement": auto_placement,
		"placement_locations": placement_locations
	})

## Starts removal mode (interactive by default).
## Same parameters as placement(), but for removing tiles instead.
func removal(building_name: String, limit := 0, auto_removal := false, removal_locations: Array = []):
	_current_action = _removal
	_current_action.start({
		"building_name": building_name,
		"limit": limit,
		"auto_removal": auto_removal,
		"removal_locations": removal_locations
	})


# ===================================================================
# 3. PROGRAMMATIC / AUTO BUILD ACTIONS
# ===================================================================

## Places a set of tiles automatically without user input.
func auto_place(building_name: String, cells: Array):
	placement(building_name, cells.size(), true, cells)

## Removes a set of tiles automatically without user input.
func auto_remove(building_name: String, cells: Array):
	removal(building_name, cells.size(), true, cells)


# ===================================================================
# 4. SHAPE HELPERS
# ===================================================================

## Places a square of tiles centered on the current mouse cell.
## - size: 1 = 1x1, 2 = 3x3, 3 = 5x5, etc.
## - fill: true = solid square, false = hollow border.
func square_placement(building_name: String, size: int, fill := true):
	_current_action = _placement_square
	_current_action.start({
		"building_name": building_name,
		"size": size,
		"fill": fill
	})

## Removes a square of tiles centered on the current mouse cell.
## - size: 1 = 1x1, 2 = 3x3, 3 = 5x5, etc.
## - fill: true = solid square, false = hollow border.
func remove_square(building_name: String, size: int, fill := true):
	_current_action = _removal_square
	_current_action.start({
		"building_name": building_name,
		"size": size,
		"fill": fill
	})
