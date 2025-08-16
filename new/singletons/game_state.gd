extends Node

# ----------------------------
# 🔗 References
# ----------------------------
#signal_bus.gd as an autoload SignalBus
@onready var resources = get_node_or_null("/root/GameResources")

# ----------------------------
# 🏷 Constants
# ----------------------------
const PLAY_PHASE_STATE_IDLE := "Idle"
const PLAY_PHASE_STATE_DRAWING := "Drawing"
const PLAY_PHASE_STATE_PLAYING := "Playing"
const PLAY_PHASE_STATE_RESOLVING := "Resolving"
const PLAY_PHASE_STATE_PLACING_STRUCTURE := "PlacingStructure"
const PLAY_PHASE_STATE_RECYCLE := "RecycleMode"

# ----------------------------
# 📊 Game State
# ----------------------------
var current_turn: int = 0
var current_phase: String = "None"
var play_phase_state: String = PLAY_PHASE_STATE_IDLE

# ----------------------------
# 🚀 Lifecycle
# ----------------------------
func _ready() -> void:
	print("[GameState] Ready")

	if SignalBus:
		SignalBus.connect("tile_effects_done", Callable(self, "_on_tile_effects_done"))
	else:
		push_warning("no signal bus found")

	if resources == null:
		push_warning("[GameState] GameResources singleton not found — resource checks disabled")

	call_deferred("start_game")

# ----------------------------
# 🔄 Turn Control
# ----------------------------
func start_game() -> void:
	current_turn = 0
	current_phase = "Play"
	play_phase_state = PLAY_PHASE_STATE_IDLE
	call_deferred("_emit_game_started")

func _emit_game_started() -> void:
	SignalBus.emit_logged("game_started")
	SignalBus.emit_logged("phase_changed", [current_phase])
	SignalBus.emit_logged("play_phase_state_changed", [play_phase_state])
	_broadcast_piles()

func advance_phase() -> void:
	SignalBus.emit_logged("cancel_active_modes")

	match current_phase:
		"Play":
			resolve_hand()
			current_phase = "Tile Effects"
			SignalBus.emit_logged("phase_changed", [current_phase])
			if structure_manager:
				structure_manager.run_tile_effects_phase()
			else:
				push_warning("No StructureManager to run tile effects — skipping")
				_on_tile_effects_done()

		"Tile Effects":
			print("[GameState] Advancing from Tile Effects → Play (next turn)")
			current_turn += 1
			SignalBus.emit_logged("turn_ended", [current_turn - 1])
			current_phase = "Play"
			SignalBus.emit_logged("phase_changed", [current_phase])

# ----------------------------
# ⏩ Phase Callbacks
# ----------------------------
func _on_tile_effects_done() -> void:
	print("[GameState] Tile Effects phase complete — advancing")
	advance_phase()

# ----------------------------
# 🛠 Utility
# ----------------------------
func set_play_phase_state(state: String) -> void:
	play_phase_state = state
	SignalBus.emit_logged("play_phase_state_changed", [state])

# ----------------------------
# 📦 Catalog + Resource Helpers
# ----------------------------
#goes somewhere. not sure where yet.
func _build_structure_request_from_card(card: Dictionary) -> Dictionary:
	# Stub: Transform card data into structure request format
	return {
		"id": card.get("id", ""),
		"type": card.get("type", ""),
		"cost": card.get("cost", 0)
	}
	
	
#goes to deck manager
func _broadcast_piles() -> void:
	# Stub: Replace with actual deck/hand/discard queries
	SignalBus.emit_logged("piles_changed", [0, 0, 0])

#goes to deck manager.
func resolve_hand() -> void:
	# Stub: Implement your core hand resolution logic
	print("[GameState] Resolving hand…")
