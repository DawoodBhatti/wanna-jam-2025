extends Control

@onready var game_state := get_node("/root/Gamestate")
@onready var deck := $Deck  # child node that holds the deck array

func _ready() -> void:
	print("[DeckManager] Ready")
	game_state.connect("game_started", Callable(self, "_on_game_started"))
	game_state.connect("phase_changed", Callable(self, "_on_phase_changed"))

func _on_game_started() -> void:
	print("[DeckManager] Game started — loading deck and drawing hand")
	game_state.deck = deck.deck
	game_state.shuffle_deck()

func _on_phase_changed(phase: String) -> void:
	print("[DeckManager] Phase changed to: ", phase)
	if phase == "Play":
		# Draw a fresh hand at the start of Play
		game_state.draw_cards(5)
	elif phase == "Tile Effects":
		# Let GameState handle advancing; DeckManager just resolves any end‑of‑hand logic if needed
		game_state.resolve_hand()
