extends Node
class_name GameState

# -----------------
# Signals
# -----------------
signal game_started
signal turn_ended(turn_number : int)
signal phase_changed(new_phase : String)
signal play_phase_ended
signal hand_drawn(cards : Array) # could rename to hand_updated
signal card_played(card_data : Dictionary)
signal play_phase_state_changed(state : String)
signal piles_changed(deck_size : int, hand_size : int, discard_size : int)
signal recycle_mode_requested(data : Dictionary)
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
# Card Data
# -----------------
var deck: Array = []
var hand: Array = []
var discard_pile: Array = []

# -----------------
# Game State
# -----------------
var current_turn: int = 0
var current_phase: String = "None"
var play_phase_state: String = PLAY_PHASE_STATE_IDLE

# -----------------
# Lifecycle
# -----------------
func _ready() -> void:
	print("[GameState] Ready")
	connect("play_phase_ended", Callable(self, "_on_play_phase_ended"))
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
	# Optional: cancel any active placement/removal mode on phase change
	emit_signal("cancel_active_modes")

	if current_phase == "Play":
		print("[GameState] Advancing from Play → Tile Effects")
		resolve_hand()
		current_phase = "Tile Effects"
		emit_signal("phase_changed", current_phase)

	elif current_phase == "Tile Effects":
		print("[GameState] Advancing from Tile Effects → Play (next turn)")
		current_turn += 1
		emit_signal("turn_ended", current_turn - 1)
		current_phase = "Play"
		emit_signal("phase_changed", current_phase)

func _on_play_phase_ended() -> void:
	print("[GameState] Play phase ended — advancing phase")
	advance_phase()

# -----------------
# Card pile manipulation
# -----------------
func shuffle_deck() -> void:
	deck.shuffle()
	_broadcast_piles()

func draw_cards(count: int) -> void:
	set_play_phase_state(PLAY_PHASE_STATE_DRAWING)
	print("[GameState] Drawing ", count, " cards")

	for i in range(count):
		if deck.is_empty():
			if discard_pile.is_empty():
				break
			deck = discard_pile
			discard_pile = []
			deck.shuffle()
		var card = deck.pop_front()
		hand.append(card)

	emit_signal("hand_drawn", hand)
	_broadcast_piles()
	set_play_phase_state(PLAY_PHASE_STATE_IDLE)

func request_play_card(card: Dictionary) -> void:
	if current_phase != "Play":
		print("[Card] Play rejected: not in Play phase")
		return
	if play_phase_state != PLAY_PHASE_STATE_IDLE:
		print("[Card] Play rejected: busy state: ", play_phase_state)
		return
	if not hand.has(card):
		print("[Card] Play rejected: card not in hand: ", card.get("name", "Unknown"))
		return
	play_card(card)

func play_card(card: Dictionary) -> void:
	set_play_phase_state(PLAY_PHASE_STATE_PLAYING)

	# Side effects defined by the card
	if card.has("on_play"):
		card["on_play"].call()

	# Sub-phase routing (build or recycle) with budget forwarding
	if card.get("builds_structure", false):
		set_play_phase_state(PLAY_PHASE_STATE_PLACING_STRUCTURE)
		emit_signal("structure_placement_requested", {
			"source_id": card.source_id,
			"atlas_coords": card.atlas_coords,
			"amount": card.get("place_amount", 1) # default 1
		})
	elif card.get("recycle_mode", false):
		set_play_phase_state(PLAY_PHASE_STATE_RECYCLE)
		emit_signal("recycle_mode_requested", {
			"amount": card.get("remove_amount", 1) # default 1
		})
	else:
		set_play_phase_state(PLAY_PHASE_STATE_IDLE)

	# Notify UI and move card once
	emit_signal("card_played", card)
	print("Played card: ", card.name)

	discard_pile.append(card)
	hand.erase(card)
	_broadcast_piles()

func resolve_hand() -> void:
	set_play_phase_state(PLAY_PHASE_STATE_RESOLVING)
	for card in hand:
		if card.has("on_end"):
			card["on_end"].call()
		discard_pile.append(card)
	hand.clear()
	_broadcast_piles()
	set_play_phase_state(PLAY_PHASE_STATE_IDLE)

# -----------------
# Utility
# -----------------
func _broadcast_piles() -> void:
	emit_signal("piles_changed", deck.size(), hand.size(), discard_pile.size())

func set_play_phase_state(state: String) -> void:
	play_phase_state = state
	emit_signal("play_phase_state_changed", state)
