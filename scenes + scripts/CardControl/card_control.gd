extends Node2D

var deck: Array = []
var hand: Array = []
var discard_pile: Array = []


@onready var game_state: Node = get_node("/root/Gamestate")  # Autoload singleton


func _ready() -> void:
	#connect signals in GameState to functions like draw hand and resolve hand
	#Callable is a type safe method to reference functions
	game_state.connect("phase_changed", Callable(self, "_on_phase_changed"))
	print("CardControl ready. Press J to draw hand, K to resolve hand, L to play first card manually, D to discard hand. \n")
	load_example_cards()


func _on_game_started() -> void:
	# Called when the game is ready — safe to initialize card systems
	shuffle_deck()


func _on_phase_changed(phase: String) -> void:
	if phase == "Play":
		draw_hand()
	elif phase == "Tile Effects":
		resolve_hand()
		game_state.emit_signal("play_phase_ended")


func _input(event):
	if event.is_action_pressed("draw_hand"):
		draw_hand()
	elif event.is_action_pressed("resolve_hand"):
		resolve_hand()
	elif event.is_action_pressed("play_first_card") and hand.size() > 0:
		play_card(hand[0])
	elif event.is_action_pressed("discard_hand"):
		discard_hand()
	elif event.is_action_pressed("print_card_piles"):
		print_card_piles()


# --- Card Logic ---
func shuffle_deck() -> void:
	deck.shuffle()
	print("Deck shuffled.")


func draw_cards(count: int) -> void:
	game_state.set_play_phase_state("Drawing")
	for i in range(count):
		if deck.is_empty():
			if discard_pile.is_empty():
				print("no cards in hand, deck or draw pile... you are probably testing...")
				break
			print("Reshuffling discard pile into deck.")
			deck = discard_pile
			discard_pile = []
			deck.shuffle()
		var card = deck.pop_front()
		hand.append(card)
		print("Drawn card: ", card.name)
	game_state.emit_signal("hand_drawn", hand)
	game_state.set_play_phase_state("Idle")


func draw_hand() -> void:
	draw_cards(3)
	print("Hand drawn:")
	for card in hand:
		print(" - ", card.name)


func play_card(card: Dictionary) -> void:
	game_state.set_play_phase_state("Playing")
	if card.has("on_play"):
		card["on_play"].call()
	game_state.emit_signal("card_played", card)
	print("Played card: ", card.name)
	discard_pile.append(card)
	hand.erase(card)
	game_state.set_play_phase_state("Idle")


func resolve_hand() -> void:
	game_state.set_play_phase_state("Resolving")
	for card in hand:
		if card.has("on_end"):
			card["on_end"].call()
		print("Resolved (unplayed) card: ", card.name)
		discard_pile.append(card)
	hand.clear()
	game_state.set_play_phase_state("Idle")


func discard_hand() -> void:
	for card in hand:
		print("Discarded card: ", card.name)
		discard_pile.append(card)
	hand.clear()


func print_card_piles() -> void:
	print("\n--- CARD PILES ---")
	print("Hand (", hand.size(), "):")
	for card in hand:
		print(" - ", card.name)
	print("Deck (", deck.size(), "):")
	for card in deck:
		print(" - ", card.name)
	print("Discard Pile (", discard_pile.size(), "):")
	for card in discard_pile:
		print(" - ", card.name)
	print("--- END ---\n")


func load_example_cards() -> void:
	print("loaded deck...")
	deck = $Deck.deck
