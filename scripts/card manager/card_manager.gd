extends Node2D

# 🧠 CardManager: Orchestrates card play, manages hand lifecycle,
# validates actions, and delegates gameplay effects.

var effects_manager: Node2D
var debug_switch: bool = true

# -------------------------------------------------------------------
# 🚦 Initialization & Signal Wiring
# -------------------------------------------------------------------
func _ready() -> void:
	effects_manager = get_node("../EffectsManager")

	SignalBus.connect("phase_changed", Callable(self, "_on_phase_changed"))
	SignalBus.connect("draw_hand_requested", Callable(self, "_on_draw_hand_requested"))
	SignalBus.connect("draw_cards_requested", Callable(self, "_on_draw_cards_requested"))
	SignalBus.connect("card_clicked", Callable(self, "_on_card_clicked"))
	SignalBus.connect("card_play_requested", Callable(self, "_on_card_play_requested"))
	SignalBus.connect("resolve_hand_requested", Callable(self, "_on_resolve_hand_requested"))

	print("[CardManager] ready!")

# -------------------------------------------------------------------
# 🧩 Utility Accessors
# -------------------------------------------------------------------
func get_card_template() -> Control:
	return $CardTemplate

# -------------------------------------------------------------------
# 🔄 Turn Management
# -------------------------------------------------------------------
func end_turn() -> void:
	SignalBus.emit_logged("resolve_hand_requested")

func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "ResolveHand":
		_on_resolve_hand_requested()

# -------------------------------------------------------------------
# 🃏 Draw Logic
# -------------------------------------------------------------------
func _on_draw_hand_requested() -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_DRAWING)
	DeckState.draw_full_hand()

func _on_draw_cards_requested(count: int) -> void:
	DeckState.draw_from_deck(count)

# -------------------------------------------------------------------
# 🎯 Card Play Routing
# -------------------------------------------------------------------
func _on_card_play_requested(card_id: String) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return

	var card: Dictionary = CardCatalogue.get_card_by_id(card_id)
	if card.is_empty():
		push_warning("[CardManager] Unknown card play requested: %s" % card_id)
		return
	if not DeckState.hand.has(card_id):
		return
	if not ResourceState.can_afford(card_id):
		if debug_switch:
			print("[CardManager] Cannot afford card: %s" % card_id)
		SignalBus.emit_logged("card_play_denied", card_id)
		return

	if card.get("builds_structure", false):
		_handle_structure_card(card_id)
	elif card.get("recycle_mode", false):
		_handle_recycle_card(card_id)
	else:
		_handle_standard_card(card_id)

	SignalBus.emit_logged("card_was_played", card_id)

	if DeckState.hand.is_empty():
		SignalBus.emit_logged("resolve_hand_requested")

# -------------------------------------------------------------------
# 🏗️ Card Type Handlers
# -------------------------------------------------------------------
func _handle_structure_card(card_id: String) -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLACING_STRUCTURE)

	var req: Dictionary = CardCatalogue.resolve_structure_payload(card_id)
	var cost: Dictionary = req.get("cost", {}) as Dictionary

	if not DeckState.can_afford(cost):
		var card: Dictionary = CardCatalogue.get_card_by_id(card_id)
		if debug_switch:
			print("Not enough resources for %s" % card.get("name", "unknown"))
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)
		return

	effects_manager.run_card_effects(card_id, "play")
	SignalBus.emit_logged("structure_placement_requested", [req])
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

func _handle_recycle_card(card_id: String) -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_RECYCLE)

	var card: Dictionary = CardCatalogue.get_card_by_id(card_id)
	var amount: int = int(card.get("remove_amount", 1))

	effects_manager.run_card_effects(card_id, "play")
	SignalBus.emit_logged("recycle_mode_requested", [{ "amount": amount }])
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

func _handle_standard_card(card_id: String) -> void:
	effects_manager.run_card_effects(card_id, "play")

# -------------------------------------------------------------------
# 🖱️ Card Interaction
# -------------------------------------------------------------------
func _on_card_clicked(card_id: String) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return

	var card: Dictionary = CardCatalogue.get_card_by_id(card_id)
	if card.is_empty():
		push_warning("[CardManager] Unknown card clicked: %s" % card_id)
		return
	if not DeckState.hand.has(card_id):
		return

	SignalBus.emit_logged("card_play_requested", card_id)

	if DeckState.hand.is_empty():
		SignalBus.emit_logged("resolve_hand_requested")

# -------------------------------------------------------------------
# ✅ Hand Resolution
# -------------------------------------------------------------------
func _on_resolve_hand_requested() -> void:
	if effects_manager == null:
		return

	for card_id: String in DeckState.hand:
		var card : Dictionary = CardCatalogue.get_card_by_id(card_id)
		for effect: Dictionary in card.get("effects_on_end", []):
			var e: Dictionary = effect.duplicate(true)
			e["instant"] = true
			effects_manager.handle_effect(e, {
				"card": card,
				"timing": "end"
			})

	DeckState.move_hand_to_discard()
	SignalBus.emit_logged("hand_resolved")
