extends Node

# 🔗 Autoloads
# signal_bus.gd as SignalBus
# resource_state.gd as ResourceState

# 🏷 Constants
const PLAY_PHASE_STATE_IDLE              := "Idle"
const PLAY_PHASE_STATE_DRAWING           := "Drawing"
const PLAY_PHASE_STATE_PLAYING           := "Playing"
const PLAY_PHASE_STATE_RESOLVING         := "Resolving"
const PLAY_PHASE_STATE_PLACING_STRUCTURE := "PlacingStructure"
const PLAY_PHASE_STATE_RECYCLE           := "RecycleMode"

# 📊 Game State
var current_turn: int = 0
var current_phase: String = "None"
var play_phase_state: String = PLAY_PHASE_STATE_IDLE

var debug_switch: bool = true

# 🚀 Lifecycle
func _ready() -> void:
	if debug_switch:
		print("[GameState] Ready")

	SignalBus.connect("hand_drawn", Callable(self, "_on_hand_drawn"))

	SignalBus.connect("hand_resolved", Callable(self, "_on_hand_resolved"))
	SignalBus.connect("end_turn_effects_finished", Callable(self, "_on_end_turn_effects_finished"))
	SignalBus.connect("resource_count_finished", Callable(self, "_on_resource_count_finished"))

	call_deferred("start_game")

# 🔄 Turn Control
func start_game() -> void:
	current_turn = 0
	set_phase("Play")

# ⏩ Phase Transitions
func set_phase(new_phase: String) -> void:
	current_phase = new_phase
	if new_phase != "Play":
		play_phase_state = PLAY_PHASE_STATE_IDLE

	SignalBus.emit_logged("phase_changed", [new_phase])

	match new_phase:
		"Turn Effects":
			SignalBus.emit_logged("end_turn_effects_started")
		"Resource Count":
			SignalBus.emit_logged("resource_count_requested")
		"Play":
			if debug_switch:
				print("[GameState] Entered Play → requesting full hand draw")
			SignalBus.emit_logged("draw_hand_requested")  # no payload

func set_play_phase_state(new_state: String) -> void:
	if play_phase_state == new_state:
		return
	if _is_transition_allowed(play_phase_state, new_state):
		play_phase_state = new_state
		SignalBus.emit_logged("play_phase_state_changed", [new_state])
		if new_state == PLAY_PHASE_STATE_RESOLVING:
			if debug_switch:
				print("[GameState] Entered Resolving → emitting resolve_hand_requested")
			SignalBus.emit_logged("resolve_hand_requested")
	else:
		push_warning("[GameState] Illegal play phase transition: %s → %s" % [play_phase_state, new_state])


func _on_hand_resolved() -> void: 
	if debug_switch: 
		print("[GameState] Resolving hand → moving to Turn Effects") 
		set_phase("Turn Effects")


func _on_end_turn_effects_finished() -> void:
	if debug_switch:
		print("[GameState] Turn Effects complete — requesting resource count")
	set_phase("Resource Count")

func _on_resource_count_finished() -> void:
	current_turn += 1
	SignalBus.emit_logged("turn_ended", [current_turn - 1])
	set_phase("Play")

func _on_draw_hand_requested() -> void:
	# GameState only updates state; drawing is delegated elsewhere
	set_play_phase_state(PLAY_PHASE_STATE_DRAWING)


func _on_hand_drawn(cards: Array) -> void:
	if play_phase_state == PLAY_PHASE_STATE_DRAWING:
		set_play_phase_state(PLAY_PHASE_STATE_PLAYING)

# 🛠 Utility
func _is_transition_allowed(from_state: String, to_state: String) -> bool:
	var allowed: Dictionary = {
		PLAY_PHASE_STATE_IDLE:              [PLAY_PHASE_STATE_DRAWING],
		PLAY_PHASE_STATE_DRAWING:           [PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_PLAYING:           [PLAY_PHASE_STATE_PLACING_STRUCTURE, PLAY_PHASE_STATE_RECYCLE, PLAY_PHASE_STATE_RESOLVING, PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_PLACING_STRUCTURE: [PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_RECYCLE:           [PLAY_PHASE_STATE_PLAYING],
		PLAY_PHASE_STATE_RESOLVING:         [PLAY_PHASE_STATE_IDLE]
	}
	return allowed.has(from_state) and to_state in allowed[from_state]


func debug_step() -> void:
	if debug_switch:
		print("\n[DebugStep] Current phase: %s | Current play phase state: %s" % [
		current_phase,
		play_phase_state
	])

	match play_phase_state:
		PLAY_PHASE_STATE_IDLE:
			if debug_switch:
				print("[DebugStep] Advancing: Idle → Drawing")
			set_play_phase_state(PLAY_PHASE_STATE_DRAWING)

		PLAY_PHASE_STATE_DRAWING:
			if debug_switch:
				print("[DebugStep] Advancing: Drawing → Playing")
			set_play_phase_state(PLAY_PHASE_STATE_PLAYING)

		PLAY_PHASE_STATE_PLAYING:
			if debug_switch:
				print("[DebugStep] Advancing: Playing → Resolving")
			set_play_phase_state(PLAY_PHASE_STATE_RESOLVING)

		PLAY_PHASE_STATE_PLACING_STRUCTURE, PLAY_PHASE_STATE_RECYCLE:
			if debug_switch:
				print("[DebugStep] Currently in a build/recycle mode — skipping manual advance for now")

		PLAY_PHASE_STATE_RESOLVING:
			if debug_switch:
				print("[DebugStep] Advancing: Resolving → Idle")
			set_play_phase_state(PLAY_PHASE_STATE_IDLE)

		_:
			print("[DebugStep] No advance mapping for: %s" % play_phase_state)
	print("\n")
