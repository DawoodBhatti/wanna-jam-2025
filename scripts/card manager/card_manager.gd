extends Node2D
# 🃏 CardManager: Handles drawing, playing, clicking, and type-specific behavior.

# --- Dependencies ---
@onready var game_state: GameState = get_node("../GameController/GameState") as GameState
@onready var effects_manager: EffectsManager = get_node("../EffectsManager") as EffectsManager

# --- Initialization ---
func _ready() -> void:
	SignalBus.connect("draw_hand_requested", Callable(self, "_on_draw_hand_requested"))
	SignalBus.connect("draw_cards_requested", Callable(self, "_on_draw_cards_requested"))
	SignalBus.connect("card_clicked", Callable(self, "_on_card_clicked"))
	SignalBus.connect("card_play_requested", Callable(self, "_on_card_play_requested"))

# ================================
# 🃏 DRAWING CARDS
# ================================

## Handles a request to draw a full new hand.
func _on_draw_hand_requested() -> void:
	game_state.set_inner_phase("drawing")
	DeckState.draw_full_hand()

## Handles a request to draw a specific number of cards.
func _on_draw_cards_requested(count: int) -> void:
	DeckState.draw_from_deck(count)

# ================================
# 🖱️ CARD INTERACTION
# ================================

func _on_card_clicked(card_id: String) -> void:
	SignalBus.emit_logged("card_play_requested", card_id)

# ================================
# ▶️ CARD PLAYING LOGIC
# ================================

## Handles the logic for playing a card:
## - Validates if it can be played
## - Routes instant and queued effects
## - Emits relevant signals
func _on_card_play_requested(card_id: String) -> void:
	if not _can_play_card(card_id):
		return

	var card := CardCatalogue.get_card_by_id(card_id)

	# Set phase for instant placement/removal cards
	if CardCatalogue.has_instant_placement(card_id):
		game_state.set_inner_phase("placing_tile")
	if CardCatalogue.has_instant_removal(card_id):
		game_state.set_inner_phase("removing_tile")

	# Route effects
	effects_manager.run_card_instant_effect(card_id)
	effects_manager.queue_card_end_turn_effect(card_id)

	SignalBus.emit_logged("card_was_played", card_id)

	# If hand is empty after playing, request resolution
	if DeckState.hand.is_empty():
		SignalBus.emit_logged("resolve_hand_requested")

# ================================
# ✅ VALIDATION HELPERS
# ================================

## Checks if a card can be interacted with (clicked/played).
func _can_interact_with_card(card_id: String) -> bool:
	if game_state.inner_phase != game_state.INNER_PHASES.playing:
		return false
	return _card_exists_in_hand(card_id)

## Checks if a card can be played:
## - Must be in the playing phase
## - Must exist in hand
## - Must be affordable
func _can_play_card(card_id: String) -> bool:
	if game_state.inner_phase != game_state.INNER_PHASES.playing:
		SignalBus.emit_logged("card_play_denied", card_id)
		return false

	if not _card_exists_in_hand(card_id):
		return false

	if not ResourceState.can_afford(card_id):
		SignalBus.emit_logged("card_play_denied", card_id)
		return false

	return true

## Checks if a card exists in the current hand.
func _card_exists_in_hand(card_id: String) -> bool:
	var card := CardCatalogue.get_card_by_id(card_id)
	return not card.is_empty() and DeckState.hand.has(card_id)

## Determines the type of a card based on its properties.
func _get_card_type(card: Dictionary) -> String:
	if card.get("triggers_placement", false):
		return "structure"
	elif card.get("triggers_removal", false):
		return "recycle"
	return "neutral"
