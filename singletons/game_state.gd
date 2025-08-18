extends Node

# ----------------------------
# 🔗 Autoloads
# ----------------------------
# signal_bus.gd as SignalBus
# resource_state.gd as ResourceState

# ----------------------------
# 🏷 Constants
# ----------------------------
const PLAY_PHASE_STATE_IDLE              := "Idle"
const PLAY_PHASE_STATE_DRAWING           := "Drawing"
const PLAY_PHASE_STATE_PLAYING           := "Playing"
const PLAY_PHASE_STATE_RESOLVING         := "Resolving"
const PLAY_PHASE_STATE_PLACING_STRUCTURE := "PlacingStructure"
const PLAY_PHASE_STATE_RECYCLE           := "RecycleMode"

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

	SignalBus.connect("resolve_hand_requested", Callable(self, "_on_resolve_hand_requested"))
	SignalBus.connect("end_turn_effects_finished", Callable(self, "_on_end_turn_effects_finished"))
	SignalBus.connect("resource_count_finished", Callable(self, "_on_resource_count_finished"))

	call_deferred("start_game")

# ----------------------------
# 🔄 Turn Control (Outer Loop)
# ----------------------------
func start_game() -> void:
	current_turn = 0
	current_phase = "Play"
	play_phase_state = PLAY_PHASE_STATE_IDLE
	call_deferred("_emit_game_started")

func _emit_game_started() -> void:
	SignalBus.emit_logged("game_started")
	SignalBus.emit_logged("phase_changed", [current_phase])
	# No idle emit here — DeckManager will set Drawing/Playing

# ----------------------------
# ⏩ Phase Transitions
# ----------------------------
func _on_resolve_hand_requested() -> void:
	print("[GameState] Resolving hand → moving to Turn Effects")
	current_phase = "Turn Effects"
	SignalBus.emit_logged("phase_changed", [current_phase])
	SignalBus.emit_logged("end_turn_effects_started")

func _on_end_turn_effects_finished() -> void:
	print("[GameState] Turn Effects complete — requesting resource count")
	current_phase = "Resource Count"
	SignalBus.emit_logged("phase_changed", [current_phase])
	SignalBus.emit_logged("resource_count_requested")

func _on_resource_count_finished() -> void:
	current_turn += 1
	SignalBus.emit_logged("turn_ended", [current_turn - 1])
	current_phase = "Play"
	set_play_phase_state(PLAY_PHASE_STATE_IDLE) # explicit call now

# ----------------------------
# 🛠 Utility
# ----------------------------
func set_play_phase_state(state: String) -> void:
	play_phase_state = state
	SignalBus.emit_logged("play_phase_state_changed", [state])

func _is_transition_allowed(from_state: String, to_state: String) -> bool:
	var allowed: Dictionary = {
		PLAY_PHASE_STATE_IDLE:              [PLAY_PHASE_STATE_DRAWING],
		PLAY_PHASE_STATE_DRAWING:           [PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_PLAYING:           [PLAY_PHASE_STATE_PLACING_STRUCTURE, PLAY_PHASE_STATE_RECYCLE, PLAY_PHASE_STATE_RESOLVING, PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_PLACING_STRUCTURE: [PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_RECYCLE:           [PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_RESOLVING:         [PLAY_PHASE_STATE_IDLE] # after turn end
	}
	return allowed.has(from_state) and to_state in allowed[from_state]


func debug_step() -> void:
	print("\n")
	print("🛠 [DEBUG STEP] Current → Turn:", current_turn,
		  "| Phase:", current_phase,
		  "| PlayPhase:", play_phase_state)
	match current_phase:
		"Play":
			match play_phase_state:
				PLAY_PHASE_STATE_IDLE:
					set_play_phase_state(PLAY_PHASE_STATE_DRAWING)
				PLAY_PHASE_STATE_DRAWING:
					set_play_phase_state(PLAY_PHASE_STATE_PLAYING)
				PLAY_PHASE_STATE_PLAYING, PLAY_PHASE_STATE_PLACING_STRUCTURE, PLAY_PHASE_STATE_RECYCLE:
					set_play_phase_state(PLAY_PHASE_STATE_RESOLVING)
				PLAY_PHASE_STATE_RESOLVING:
					_on_resolve_hand_requested()

		"Turn Effects":
			_on_end_turn_effects_finished()

		"None", "Resource Count":
			_on_resource_count_finished()

	print("➡ [DEBUG STEP] Now     → Turn:", current_turn,
		  "| Phase:", current_phase,
		  "| PlayPhase:", play_phase_state)
	print("--------------------------------------------------")
	print("\n")
