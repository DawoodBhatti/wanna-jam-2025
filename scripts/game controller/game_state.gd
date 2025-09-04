extends Node
class_name GameState

# ================================
# 📜 Phase Definitions
# ================================

## Outer phases represent the broad stages of a turn.
const OUTER_PHASES := {
	"none": "None",
	"play": "Play",
	"turn_effects": "Turn Effects",
	"resource_count": "Resource Count"
}

## Inner phases exist within the "Play" outer phase and represent finer-grained states.
const INNER_PHASES := {
	"idle": "Idle",
	"drawing": "Drawing",
	"playing": "Playing",
	"placing_tile": "PlacingTile",
	"removing_tile": "RemovingTile",
	"resolving": "Resolving"
}

# ================================
# 📦 State Variables
# ================================

var current_turn: int = 0
var outer_phase: String = "None"
var inner_phase: String = INNER_PHASES.idle

# ================================
# 🔄 Lifecycle
# ================================

## Resets the game state to its initial values.
func start_up() -> void:
	current_turn = 0
	outer_phase = "None"
	inner_phase = INNER_PHASES.idle

## Advances the game to the next turn.
func advance_turn() -> void:
	current_turn += 1

# ================================
# 🚦 External Phase Setters
# ================================

## Sets the outer phase if the transition is valid.
func set_outer_phase(phase: String) -> void:
	var target := _resolve_outer_phase(phase)
	if target == null or not _is_outer_transition_allowed(outer_phase, target):
		_critical_error("Invalid outer phase transition from " + outer_phase + " to " + str(phase))
		return
	outer_phase = target

## Sets the inner phase if the transition is valid.
func set_inner_phase(phase: String) -> void:
	var target := _resolve_inner_phase(phase)
	if target == null or not _is_inner_transition_allowed(inner_phase, target):
		_critical_error("Invalid inner phase transition from " + inner_phase + " to " + str(phase))
		return
	inner_phase = target

# ================================
# 🧠 Internal Helpers
# ================================

## Resolves a string key to a valid outer phase value.
func _resolve_outer_phase(key: String) -> String:
	return OUTER_PHASES.get(key.to_lower(), null)

## Resolves a string key to a valid inner phase value.
func _resolve_inner_phase(key: String) -> String:
	return INNER_PHASES.get(key.to_lower(), null)

## Checks if an outer phase transition is allowed.
func _is_outer_transition_allowed(from_state: String, to_state: String) -> bool:
	var allowed: Dictionary = {
		OUTER_PHASES.none:           [OUTER_PHASES.play],
		OUTER_PHASES.play:           [OUTER_PHASES.turn_effects],
		OUTER_PHASES.turn_effects:   [OUTER_PHASES.resource_count],
		OUTER_PHASES.resource_count: [OUTER_PHASES.play]
	}
	return allowed.has(from_state) and to_state in allowed[from_state]

## Checks if an inner phase transition is allowed.
func _is_inner_transition_allowed(from_state: String, to_state: String) -> bool:
	var allowed: Dictionary = {
		INNER_PHASES.idle:          [INNER_PHASES.drawing],
		INNER_PHASES.drawing:       [INNER_PHASES.playing],
		INNER_PHASES.playing:       [INNER_PHASES.placing_tile, INNER_PHASES.removing_tile, INNER_PHASES.resolving, INNER_PHASES.playing],
		INNER_PHASES.placing_tile:  [INNER_PHASES.playing],
		INNER_PHASES.removing_tile: [INNER_PHASES.playing],
		INNER_PHASES.resolving:     [INNER_PHASES.idle]
	}
	return allowed.has(from_state) and to_state in allowed[from_state]

# ================================
# 💥 Error Handling
# ================================

## Handles invalid phase transitions by logging an error and pausing the game.
func _critical_error(message: String) -> void:
	push_error("[GameState] CRITICAL: " + message)
	get_tree().paused = true
