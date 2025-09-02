extends Node2D

@onready var effects_manager: EffectsManager = get_node("../EffectsManager") as EffectsManager

var debug_switch: bool = true

func _ready() -> void:
	SignalBus.connect("phase_changed", Callable(self, "_on_phase_changed"))
	SignalBus.connect("draw_hand_requested", Callable(self, "_on_draw_hand_requested"))
	SignalBus.connect("draw_cards_requested", Callable(self, "_on_draw_cards_requested"))
	SignalBus.connect("card_clicked", Callable(self, "_on_card_clicked"))
	SignalBus.connect("card_play_requested", Callable(self, "_on_card_play_requested"))
	SignalBus.connect("resolve_hand_requested", Callable(self, "_on_resolve_hand_requested"))

# --- Turn Management ---
func end_turn() -> void:
	SignalBus.emit_logged("resolve_hand_requested")

func _on_phase_changed(new_phase: String) -> void:
	# Note: GameState handles the resolving trigger; this hook is kept for future needs.
	pass

# --- Draw Logic ---
func _on_draw_hand_requested() -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_DRAWING)
	DeckState.draw_full_hand()

func _on_draw_cards_requested(count: int) -> void:
	DeckState.draw_from_deck(count)

# --- Card Play Routing ---
func _on_card_play_requested(card_id: String) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return

	var card: Dictionary = CardCatalogue.get_card_by_id(card_id)
	if card.is_empty() or not DeckState.hand.has(card_id):
		return

	if not ResourceState.can_afford(card_id):
		if debug_switch:
			print("[CardManager] Cannot afford card: %s" % card_id)
		SignalBus.emit_logged("card_play_denied", card_id)
		return

	# Instant effects now
	effects_manager.run_card_instant_effect(card_id)

	# Queue end-turn effects for later
	effects_manager.queue_card_end_turn_effect(card_id)

	if card.get("builds_structure", false):
		_handle_structure_card(card_id)
	elif card.get("recycle_mode", false):
		_handle_recycle_card(card_id)

	SignalBus.emit_logged("card_was_played", card_id)

	if DeckState.hand.is_empty():
		SignalBus.emit_logged("resolve_hand_requested")

# --- Card Type Handlers ---
func _handle_structure_card(card_id: String) -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLACING_TILE)
	var req: Dictionary = CardCatalogue.resolve_structure_payload(card_id)
	var cost: Dictionary = req.get("cost", {}) as Dictionary
	if not DeckState.can_afford(cost):
		if debug_switch:
			print("Not enough resources for %s" % CardCatalogue.get_card_by_id(card_id).get("name", "unknown"))
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)
		return
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

func _handle_recycle_card(card_id: String) -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_RECYCLE)
	var amount: int = int(CardCatalogue.get_card_by_id(card_id).get("remove_amount", 1))
	SignalBus.emit_logged("recycle_mode_requested", [{ "amount": amount }])
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

# --- Card Interaction ---
func _on_card_clicked(card_id: String) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return
	if CardCatalogue.get_card_by_id(card_id).is_empty() or not DeckState.hand.has(card_id):
		return
	SignalBus.emit_logged("card_play_requested", card_id)
	if DeckState.hand.is_empty():
		SignalBus.emit_logged("resolve_hand_requested")


# --- Hand Resolution ---
func _on_resolve_hand_requested() -> void:
	# Queue remain effects for all cards still in hand
	if effects_manager != null:
		for card_id: String in DeckState.hand:
			effects_manager.queue_card_remain_effect(card_id)
	else:
		push_warning("[CardManager] EffectsManager not found; skipping remain-effect queue")

	DeckState.move_hand_to_discard()
	SignalBus.emit_logged("hand_resolved")
