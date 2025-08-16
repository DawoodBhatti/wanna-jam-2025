extends Node

# -----------------
# Signals
# -----------------
signal game_started
signal turn_ended(turn_number: int)
signal phase_changed(new_phase: String)
signal hand_drawn(cards: Array) # could rename to hand_updated
signal card_played(card_data: Dictionary)
signal play_phase_state_changed(state: String)
signal piles_changed(deck_size: int, hand_size: int, discard_size: int)
signal recycle_mode_requested(data: Dictionary)
signal structure_placement_requested(structure_info: Dictionary)

# Optional: allow StructureManager/BaseGrid to cancel when phase changes
signal cancel_active_modes

# -----------------
# Constants
# -----------------
const PLAY_PHASE_STATE_IDLE := "Idle"
const PLAY_PHASE_STATE_DRAWING := "Drawing"
const PLAY_PHASE_STATE_PLAYING := "Playing"
const PLAY_PHASE_STATE_RESOLVING := "Resolving"
const PLAY_PHASE_STATE_PLACING_STRUCTURE := "PlacingStructure"
const PLAY_PHASE_STATE_RECYCLE := "RecycleMode"


# -----------------
# Game State
# -----------------
var current_turn: int = 0
var current_phase: String = "None"
var play_phase_state: String = PLAY_PHASE_STATE_IDLE

# -----------------
# References
# -----------------
var structure_manager: StructureManager
var resources: Node # GameResources singleton

# -----------------
# Lifecycle
# -----------------
func _ready() -> void:
	print("[GameState] Ready")

	structure_manager = get_node("/root/main/StructureManager") as StructureManager
	if structure_manager:
		structure_manager.connect("tile_effects_done", Callable(self, "_on_tile_effects_done"))

	resources = get_node_or_null("/root/GameResources")
	if resources == null:
		push_warning("[GameState] GameResources singleton not found — resource checks disabled")

	call_deferred("start_game")

# -----------------
# Turn control
# -----------------
func start_game() -> void:
	current_turn = 0
	current_phase = "Play"
	play_phase_state = PLAY_PHASE_STATE_IDLE
	call_deferred("_emit_game_started")

func _emit_game_started() -> void:
	emit_signal("game_started")
	emit_signal("phase_changed", current_phase)
	emit_signal("play_phase_state_changed", play_phase_state)
	_broadcast_piles()

func advance_phase() -> void:
	emit_signal("cancel_active_modes")

	match current_phase:
		"Play":
			resolve_hand()
			current_phase = "Tile Effects"
			emit_signal("phase_changed", current_phase)
			if structure_manager:
				structure_manager.run_tile_effects_phase()
			else:
				push_warning("No StructureManager to run tile effects — skipping")
				_on_tile_effects_done()

		"Tile Effects":
			print("[GameState] Advancing from Tile Effects → Play (next turn)")
			current_turn += 1
			emit_signal("turn_ended", current_turn - 1)
			current_phase = "Play"
			emit_signal("phase_changed", current_phase)

# -----------------
# Phase callbacks
# -----------------
func _on_tile_effects_done() -> void:
	print("[GameState] Tile Effects phase complete — advancing")
	advance_phase()


func _get_resource_amount(res: String) -> int:
	if resources == null:
		return 0
	match res:
		"stone":
			return int(resources.stone_count)
		"wood":
			return int(resources.wood_count)
		"food":
			return int(resources.food_count)
		"pop":
			return int(resources.pop_count)
		_:
			return 0
