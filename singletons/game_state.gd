extends Node
class_name GameState

# --- Signals ---
signal game_started
signal turn_ended(turn_number : int)
signal phase_changed(new_phase : String)
signal play_phase_ended
signal hand_drawn(cards : Array)  # consider renaming to hand_updated
signal card_played(card_data : Dictionary)
signal play_phase_state_changed(state : String)
signal piles_changed(deck_size : int, hand_size : int, discard_size : int)

# --- Card Data ---
var deck: Array = []
var hand: Array = []
var discard_pile: Array = []

# --- Game State ---
var current_turn: int = 0
var current_phase: String = "None"
var play_phase_state: String = "Idle"

func _ready() -> void:
	print("[GameState] Ready")
	connect("play_phase_ended", Callable(self, "_on_play_phase_ended"))
	call_deferred("start_game")

# --- Turn control ---
func start_game() -> void:
	current_turn = 0
	current_phase = "Play"
	play_phase_state = "Idle"
	call_deferred("_emit_game_started")

func _emit_game_started() -> void:
	emit_signal("game_started")
	emit_signal("phase_changed", current_phase)
	emit_signal("play_phase_state_changed", play_phase_state)
	_broadcast_piles()

func advance_phase() -> void:
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

# --- Card pile manipulation ---
func shuffle_deck() -> void:
	deck.shuffle()
	_broadcast_piles()

func draw_cards(count: int) -> void:
	set_play_phase_state("Drawing")
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
	emit_signal("hand_drawn", hand)  # ✅ correct usage
	_broadcast_piles()
	set_play_phase_state("Idle")

func request_play_card(card: Dictionary) -> void:
	if current_phase != "Play":
		print("[Card] Play rejected: not in Play phase")
		return
	if play_phase_state != "Idle":
		print("[Card] Play rejected: busy state: ", play_phase_state)
		return
	if not hand.has(card):
		print("[Card] Play rejected: card not in hand: ", card.get("name", "Unknown"))
		return
	play_card(card)
	
	
func play_card(card: Dictionary) -> void:
	set_play_phase_state("Playing")

	if card.has("on_play"):
		card["on_play"].call()

	emit_signal("card_played", card)  # 🔹 UI will handle visuals
	print("Played card: ", card.name)

	discard_pile.append(card)
	hand.erase(card)
	_broadcast_piles()

	set_play_phase_state("Idle")
	
	
func resolve_hand() -> void:
	set_play_phase_state("Resolving")
	for card in hand:
		if card.has("on_end"):
			card["on_end"].call()
		discard_pile.append(card)
	hand.clear()
	_broadcast_piles()
	set_play_phase_state("Idle")

# --- Utility ---
func _broadcast_piles() -> void:
	emit_signal("piles_changed", deck.size(), hand.size(), discard_pile.size())

func set_play_phase_state(state: String) -> void:
	play_phase_state = state
	emit_signal("play_phase_state_changed", state)
