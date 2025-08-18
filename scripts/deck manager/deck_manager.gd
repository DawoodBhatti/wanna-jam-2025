extends Node2D
class_name DeckManager

var effects_manager : Node2D
var _is_ending_turn := false

# -----------------------------------------------------------------------------
# 🃏 DeckManager — Card lifecycle controller
# -----------------------------------------------------------------------------
func _ready() -> void:
	effects_manager = get_node("../EffectsManager")

	if DeckState.deck.is_empty():
		DeckState.deck.append_array(CardCatalogue.deck.duplicate(true))
		DeckState.shuffle_deck()

	SignalBus.connect("phase_changed", Callable(self, "_on_phase_changed"))
	SignalBus.connect("card_clicked", Callable(self, "_on_card_clicked"))
	SignalBus.connect("resolve_hand_requested", Callable(self, "_on_resolve_hand_requested"))

	print("[DeckManager] ready!")

func get_card_template() -> Control:
	return $CardTemplate

# -------------------------
# Turn-ending entry point
# -------------------------
func end_turn() -> void:
	if _is_ending_turn:
		return
	_is_ending_turn = true

	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_RESOLVING)
	initiate_hand_resolve()

func initiate_hand_resolve() -> void:
	SignalBus.emit_logged("resolve_hand_requested")

# -------------------------
# Phase handling
# -------------------------
func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "Play":
		_start_play_cycle()

func _start_play_cycle() -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_DRAWING)
	var drawn: Array = DeckState.draw_from_deck(5)
	SignalBus.emit_logged("hand_drawn", [drawn])
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

# -------------------------
# Card clicks
# -------------------------
func _on_card_clicked(card_data: Dictionary) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return
	if not DeckState.hand.has(card_data):
		return

	_play_card_with_rules(card_data)

	if DeckState.hand.is_empty():
		initiate_hand_resolve()

# -------------------------
# Playing logic
# -------------------------
func _play_card_with_rules(card: Dictionary) -> void:
	var builds_structure: bool = bool(card.get("builds_structure", false))
	var recycle_mode: bool = bool(card.get("recycle_mode", false))

	if builds_structure:
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLACING_STRUCTURE)
		var req: Dictionary = _resolve_structure_request(card)
		var cost: Dictionary = req.get("cost", {})
		if not DeckState.can_afford(cost):
			print("Not enough resources for %s" % card.get("name", "unknown"))
			GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)
			return

		_run_on_play_effects(card)
		SignalBus.emit_logged("structure_placement_requested", [req])
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

	elif recycle_mode:
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_RECYCLE)
		_run_on_play_effects(card)
		SignalBus.emit_logged("recycle_mode_requested", [{ "amount": int(card.get("remove_amount", 1)) }])
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

	else:
		_run_on_play_effects(card)

	DeckState.move_card_to_discard(card)
	SignalBus.emit_logged("card_played", [card])

# -------------------------
# Structure resolution
# -------------------------
func _resolve_structure_from_catalog(card: Dictionary) -> Dictionary:
	var info: Dictionary = DeckState.get_structure_info_from_card(card)
	var layer_name: String = info.layer
	var source_name: String = info.source_name
	var tile_name: String = info.tile_name
	var cost: Dictionary = info.cost

	var resolved_source_id: int = -1
	var resolved_atlas: Vector2i = Vector2i(-1, -1)

	if source_name != "" and tile_name != "":
		var source_dict: Dictionary = CardCatalogue.catalog.get(layer_name, {}).get(source_name, {}) as Dictionary
		if not source_dict.is_empty():
			resolved_source_id = int(source_dict.get("source_id", -1))
			resolved_atlas = Vector2i(source_dict.get("tiles", {}).get(tile_name, Vector2i(-1, -1)))
			cost = Dictionary(source_dict.get("cost", cost))
		else:
			push_error("[DeckManager] Catalog entry not found for %s/%s" % [source_name, tile_name])

	elif card.has("source_id") and card.has("atlas_coords"):
		var sid: int = card.get("source_id", -1)
		var atlas: Vector2i = card.get("atlas_coords", Vector2i(-1, -1))
		for s_name: String in CardCatalogue.catalog.get(layer_name, {}).keys():
			var sd: Dictionary = CardCatalogue.catalog[layer_name][s_name]
			if int(sd.get("source_id", -9999)) == sid:
				source_name = s_name
				for t_name: String in sd.get("tiles", {}).keys():
					if Vector2i(sd["tiles"][t_name]) == atlas:
						tile_name = t_name
						break
				cost = Dictionary(sd.get("cost", cost))
				resolved_source_id = sid
				resolved_atlas = atlas
				break

	if resolved_source_id < 0 or resolved_atlas == Vector2i(-1, -1):
		push_error("[DeckManager] Could not resolve valid tile for card: %s" % card.get("name", ""))

	return {
		"layer": layer_name,
		"source_name": source_name,
		"tile_name": tile_name,
		"source_id": resolved_source_id,
		"atlas_coords": resolved_atlas,
		"amount": info.place_amount,
		"cost": cost
	}

func _resolve_structure_request(card: Dictionary) -> Dictionary:
	if card.get("structure") != null:
		var s: Dictionary = card.structure
		return {
			"layer": s.get("layer", ""),
			"source_name": s.get("source_name", ""),
			"tile_name": s.get("tile_name", ""),
			"source_id": int(CardCatalogue.catalog
				.get(s.layer, {})
				.get(s.source_name, {})
				.get("source_id", -1)),
			"atlas_coords": Vector2i(CardCatalogue.catalog
				.get(s.layer, {})
				.get(s.source_name, {})
				.get("tiles", {})
				.get(s.tile_name, Vector2i(-1, -1))),
			"amount": int(s.get("place_amount", 1)),
			"cost": card.get("cost", {})
		}
	return _resolve_structure_from_catalog(card)

# -------------------------
# Hand resolution
# -------------------------
func _on_resolve_hand_requested() -> void:
	if effects_manager == null:
		return

	for card: Dictionary in DeckState.hand:
		for effect: Dictionary in card.get("effects_on_end", []):
			var e = effect.duplicate(true)
			e["instant"] = false
			effects_manager.handle_effect(e, { "card": card, "timing": "end" })

	DeckState.move_hand_to_discard()

	# Only emit outcome; GameState will handle advancing phase & starting effects
	SignalBus.emit_logged("hand_resolved")

# -------------------------
# Play-phase effect delegation
# -------------------------
func _run_on_play_effects(card: Dictionary) -> void:
	if effects_manager == null:
		return
	for effect: Dictionary in card.get("effects_on_play", []):
		var e = effect.duplicate(true)
		e["instant"] = true
		effects_manager.handle_effect(e, { "card": card, "timing": "play" })
