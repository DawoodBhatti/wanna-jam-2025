extends Node
class_name ResolutionWatcher

"""
The ResolutionWatcher coordinates the end-of-turn resolution process.
It ensures that resolution only begins when the game is in a valid state,
and can defer resolution if a blocking action (such as tile placement or removal)
is still in progress.

It works closely with:
- **GameState** to check and update the current inner phase.
- **GameController** to integrate resolution into the overall turn flow.
- **EffectsManager** indirectly, by triggering the queuing of remain effects.
- **DeckState** to move cards from the hand to the discard pile.

The watcher listens for relevant signals (e.g., `hand_resolved`, `construction_action_completed`)
and emits its own (`resolve_hand_started`, `hand_resolved`) to drive the resolution sequence.
"""

@onready var game_state: GameState = get_node("../GameState") as GameState
@onready var game_controller: Node = get_node("../../GameController")

var is_resolving: bool = false

# ================================
# 🚀 Lifecycle
# ================================

## Connects to the `hand_resolved` signal to reset resolution state.
func _ready() -> void:
	SignalBus.connect("hand_resolved", Callable(self, "_on_hand_resolved"))

# ================================
# 📜 Resolution Requests
# ================================

## Requests that resolution begin.
## If already resolving, ignores the request.
## If a blocking build action is in progress, defers until it completes.
func request_resolution() -> void:
	if is_resolving:
		return

	var phase := game_state.inner_phase
	if phase == game_state.INNER_PHASES.placing_tile or phase == game_state.INNER_PHASES.removing_tile:
		# Defer resolution until construction is complete
		SignalBus.connect("construction_action_completed", Callable(self, "_resume_resolution"), CONNECT_ONE_SHOT)
	else:
		game_state.set_inner_phase("resolving")
		_start_resolution()

# ================================
# ⏸ Deferred Resolution
# ================================

## Resumes resolution after a blocking construction action completes.
func _resume_resolution(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	if game_state.inner_phase == "Playing":
		game_state.set_inner_phase("Resolving")
	_start_resolution()

# ================================
# ▶️ Resolution Execution
# ================================

## Starts the resolution process:
## - Marks as resolving
## - Emits `resolve_hand_started`
## - Moves hand to discard if not empty
## - Sets phase to idle and emits `hand_resolved`
func _start_resolution() -> void:
	is_resolving = true
	SignalBus.emit_logged("resolve_hand_started")

	if not DeckState.hand.is_empty():
		DeckState.move_hand_to_discard()

	game_state.set_inner_phase("idle")
	SignalBus.emit_logged("hand_resolved")

# ================================
# 🛑 Resolution Completion
# ================================

## Handles the `hand_resolved` signal by marking resolution as complete.
func _on_hand_resolved() -> void:
	is_resolving = false
