extends Node
class_name GameController

"""
The GameController is the central orchestrator of the game’s high-level flow.
It manages transitions between outer phases (e.g., Play, Turn Effects, Resource Count)
and inner phases (e.g., Playing, Resolving), ensuring that the correct systems are triggered at the right time.

While it holds the core sequencing logic, it delegates domain-specific responsibilities to other managers:
- **GameState**: Tracks and updates the current outer/inner phase and turn number.
- **ResolutionWatcher**: Oversees the resolution of the player’s hand at the end of a turn.
- **EffectsManager**: Handles the execution of instant and queued effects.

The GameController listens to global signals from these systems (and others like the ConstructionManager)
and responds by updating phases, queuing effects, or advancing the turn.
This separation keeps the GameController focused on orchestration while allowing each subsystem
to manage its own internal logic.
"""

@onready var game_state: GameState = $GameState
@onready var resolution_watcher: ResolutionWatcher = $ResolutionWatcher
@onready var effects_manager: EffectsManager = get_node("../EffectsManager")

# ================================
# 🚀 Lifecycle
# ================================

## Connects to global signals and starts the game after initialisation.
func _ready() -> void:
	SignalBus.connect("hand_drawn", Callable(self, "_on_hand_drawn"))
	SignalBus.connect("end_turn_tile_effects_queued", Callable(self, "_on_end_turn_tile_effects_queued"))
	SignalBus.connect("end_turn_effects_finished", Callable(self, "_on_end_turn_effects_finished"))
	SignalBus.connect("resource_count_finished", Callable(self, "_on_resource_count_finished"))
	SignalBus.connect("construction_action_completed", Callable(self, "_on_construction_action_completed"))
	SignalBus.connect("resolve_hand_requested", Callable(self, "_on_resolve_hand_requested"))
	SignalBus.connect("resolve_hand_started", Callable(self, "_on_resolve_hand_started"))
	SignalBus.connect("hand_resolved", Callable(self, "_on_hand_resolved"))

	call_deferred("start_game")

# ================================
# 🎮 Game Lifecycle
# ================================

## Starts the game, initialises GameState, and enters the Play phase.
func start_game() -> void:
	game_state.start_up()
	SignalBus.emit_logged("game_started")
	_set_outer_phase("play")

# ================================
# 🔄 Phase Control
# ================================

## Sets the outer phase and triggers its entry logic.
func _set_outer_phase(phase: String) -> void:
	SignalBus.emit_logged("outer_phase_changed", phase)
	_handle_outer_phase_entry(phase)

## Sets the inner phase and triggers its entry logic.
func _set_inner_phase(phase: String) -> void:
	SignalBus.emit_logged("inner_phase_changed", phase)
	_handle_inner_phase_entry(phase)

## Handles logic that should run automatically when entering an outer phase.
func _handle_outer_phase_entry(phase: String) -> void:
	match phase:
		"play":
			game_state.set_outer_phase("play")
			SignalBus.emit_logged("draw_hand_requested")
		"turn_effects":
			game_state.set_outer_phase("turn_effects")
			SignalBus.emit_logged("queue_end_turn_tile_effects")
		"resource_count":
			game_state.set_outer_phase("resource_count")
			SignalBus.emit_logged("resource_count_requested")

## Handles logic that should run automatically when entering an inner phase.
func _handle_inner_phase_entry(phase: String) -> void:
	match phase:
		"playing":
			game_state.set_inner_phase("playing")
		"resolving":
			SignalBus.emit_logged("resolve_hand_requested")

# ================================
# 📢 Event Handlers
# ================================

## Handles completion of a construction action.
## If in Play phase and placing/removing a tile, returns to Playing phase.
func _on_construction_action_completed(_mode: String, _data: Dictionary, _count: int) -> void:
	if game_state.outer_phase == "Play":
		if game_state.inner_phase in ["PlacingTile", "RemovingTile"]:
			_set_inner_phase("playing")

## Handles when the hand is drawn, switching to Playing phase.
func _on_hand_drawn(_cards: Array) -> void:
	_set_inner_phase("playing")

## Handles when the hand is resolved, moving to Turn Effects phase.
func _on_hand_resolved() -> void:
	_set_outer_phase("turn_effects")

## Handles when end-turn tile effects are queued, starting the drain process.
func _on_end_turn_tile_effects_queued() -> void:
	SignalBus.emit_logged("end_turn_effects_started")

## Handles when all end-turn effects are finished, moving to Resource Count phase.
func _on_end_turn_effects_finished() -> void:
	_set_outer_phase("resource_count")

## Handles when resource counting is finished, advancing the turn and returning to Play phase.
func _on_resource_count_finished() -> void:
	game_state.advance_turn()
	SignalBus.emit_logged("turn_ended", [game_state.current_turn - 1])
	_set_outer_phase("play")

## Handles a request to resolve the hand by delegating to the ResolutionWatcher.
func _on_resolve_hand_requested() -> void:
	resolution_watcher.request_resolution()

## Handles the start of resolution, queuing remain effects for all cards in hand.
func _on_resolve_hand_started() -> void:
	for card_id in DeckState.hand:
		effects_manager.queue_card_remain_effect(card_id)
