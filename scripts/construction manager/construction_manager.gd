# construction_manager.gd
# Orchestrates building actions. The only public API for placement, painting, and removal.

# =============================================================================
# BUILDING SYSTEM – QUICK REFERENCE
# =============================================================================
# construction_manager.gd       – Orchestrates build mode; starts/stops PlacementAction, RemovalAction, and shape-based actions.
# IBuildAction.gd           – Base interface for all build actions; defines start(), process_input(), and stop() lifecycle methods.
#
# build_catalogue.gd        – Central registry of all buildable definitions; helper methods included.
#
# placement.gd              – Handles building placement; caches tile data once; calls PlacementService.
# placement_square.gd       – Shape action: places a square of tiles in one click; uses PlacementService for preview/commit.
# placement_service.gd      – Core placement/preview logic; validates via PlacementRules; updates Level layers; emits placement signals.
# placement_rules.gd        – Validates if a building can be placed at a given cell (terrain, collisions, resources, etc.).
#
# removal.gd                – Handles building removal; calls RemovalService.
# removal_square.gd         – Shape action: removes a square of tiles in one click; uses RemovalService for preview/commit.
# removal_service.gd        – Core removal/preview logic; validates via RemovalRules; updates Level layers; emits removal signals.
# removal_rules.gd          – Validates if a building/tile can be removed from a given cell (ownership, dependencies, etc.).
#
# =============================================================================
extends Node

# -------------------------------------------------------------------
# NODE REFERENCES
# -------------------------------------------------------------------
@onready var _placement = $Placement
@onready var _placement_square = $PlacementShapes/PlacementSquare
@onready var _removal = $Removal
@onready var _removal_square = $RemovalShapes/RemovalSquare
@onready var game_state: GameState = get_node("../GameController/GameState") as GameState

# -------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------
var _current_action: IBuildAction = null
var _current_signal: String = ""


# ===================================================================
# 1. LIFECYCLE & STATE MANAGEMENT
# ===================================================================

## Stops the current build action (placement or removal) and clears connected signals.
## This "unplugs" the manager from the active action so it won't react to old signals.
func stop():
	if _current_action:
		# Disconnect from the active action's completion signal
		if _current_signal != "" and SignalBus.is_connected(_current_signal, Callable(self, "_on_action_completed")):
			SignalBus.disconnect(_current_signal, Callable(self, "_on_action_completed"))
			_current_signal = ""

		_current_action = null

## Forwards all input events to the active build action.
func _input(event):
	if _current_action:
		_current_action.process_input(event)


# ===================================================================
# 2. INTERACTIVE BUILD ACTIONS
# ===================================================================

## Starts placement mode (interactive by default).
func placement(tile_name: String, limit := 0, auto_placement := false, placement_locations: Array = []):
	_start_action(_placement, "placement_completed")
	_current_action.start({
		"tile_name": tile_name,
		"limit": limit,
		"auto_placement": auto_placement,
		"placement_locations": placement_locations
	})

## Starts removal mode (interactive by default).
func removal(tile_name: String, limit := 0, auto_removal := false, removal_locations: Array = []):
	_start_action(_removal, "removal_completed")
	_current_action.start({
		"tile_name": tile_name,
		"limit": limit,
		"auto_removal": auto_removal,
		"removal_locations": removal_locations
	})


# ===================================================================
# 3. PROGRAMMATIC / AUTO BUILD ACTIONS
# ===================================================================

## Places a set of tiles automatically without user input.
func auto_place(tile_name: String, cells: Array):
	placement(tile_name, cells.size(), true, cells)

## Removes a set of tiles automatically without user input.
func auto_remove(tile_name: String, cells: Array):
	removal(tile_name, cells.size(), true, cells)


# ===================================================================
# 4. SHAPE HELPERS
# ===================================================================

## Places a square of tiles centered on the current mouse cell.
## - size: 1 = 1x1, 2 = 3x3, 3 = 5x5, etc.
## - fill: true = solid square, false = hollow border.
func square_placement(tile_name: String, size: int, fill := true):
	_start_action(_placement_square, "placement_completed")
	_current_action.start({
		"tile_name": tile_name,
		"size": size,
		"fill": fill
	})


## Removes a square of tiles centered on the current mouse cell.
## - size: 1 = 1x1, 2 = 3x3, 3 = 5x5, etc.
## - fill: true = solid square, false = hollow border.
func remove_square(tile_name: String, size: int, fill := true):
	_start_action(_removal_square, "removal_completed")
	_current_action.start({
		"tile_name": tile_name,
		"size": size,
		"fill": fill
	})


# ===================================================================
# 5. INTERNAL HELPERS
# ===================================================================

## Starts an action and connects its completion signal to the manager's stop().
## This is the "plug in" step — we listen only to the active action's completion.
func _start_action(action: IBuildAction, completion_signal: String):
	# Stop any existing action first (also "unplugs" old signal)
	stop()

	_current_action = action
	_current_signal = completion_signal

	# Connect to the completion signal so we can stop cleanly when the action finishes
	if not SignalBus.is_connected(completion_signal, Callable(self, "_on_action_completed")):
		SignalBus.connect(completion_signal, Callable(self, "_on_action_completed"))


## Called when the active action signals completion.
## This is the "plug out" step — we stop the action and disconnect its signal.
func _on_action_completed(_mode, _data, _count):
	stop()
	#TODO would need to fix this so it emits the right count signal...
	SignalBus.emit_logged("construction_action_completed", [_mode, _data, _count])
