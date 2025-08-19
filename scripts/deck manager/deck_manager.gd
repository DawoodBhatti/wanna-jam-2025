extends Node2D

var effects_manager: Node2D

#TODO: some refactoring. we might be able to split unique functions into card template...


func _ready() -> void:
	effects_manager = get_node("../EffectsManager")

	# Orchestration signals
	SignalBus.connect("phase_changed", Callable(self, "_on_phase_changed"))

	# Intent signals — no payloads in full‑hand path
	SignalBus.connect("draw_hand_requested", Callable(self, "_on_draw_hand_requested"))
	SignalBus.connect("draw_cards_requested", Callable(self, "_on_draw_cards_requested"))

	# Game interactions
	SignalBus.connect("card_clicked", Callable(self, "_on_card_clicked"))
	SignalBus.connect("resolve_hand_requested", Callable(self, "_on_resolve_hand_requested"))

	print("[DeckManager] ready!")

func get_card_template() -> Control:
	return $CardTemplate

func end_turn() -> void:
	SignalBus.emit_logged("resolve_hand_requested")

func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "ResolveHand":
		_on_resolve_hand_requested()

# 🔹 FULL HAND DRAW PATH — just request; DeckState emits "hand_drawn"
func _on_draw_hand_requested() -> void:
	GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_DRAWING)
	DeckState.draw_full_hand()

# 🔹 PARTIAL DRAW PATH — same as above
func _on_draw_cards_requested(count: int) -> void:
	DeckState.draw_from_deck(count)

func _on_card_clicked(card_data: Dictionary) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return
	if not DeckState.hand.has(card_data):
		return

	_play_card_with_rules(card_data)

	if DeckState.hand.is_empty():
		SignalBus.emit_logged("resolve_hand_requested")
	
func _play_card_with_rules(card: Dictionary) -> void:
	var builds_structure: bool = bool(card.get("builds_structure", false))
	var recycle_mode: bool = bool(card.get("recycle_mode", false))
	
	if builds_structure:
		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLACING_STRUCTURE)

		var req: Dictionary = _resolve_structure_request(card)
		var cost: Dictionary = req.get("cost", {}) as Dictionary

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
		SignalBus.emit_logged("recycle_mode_requested", [{
			"amount": int(card.get("remove_amount", 1))
		}])

		GameState.set_play_phase_state(GameState.PLAY_PHASE_STATE_PLAYING)

	else:
		_run_on_play_effects(card)
	
	SignalBus.emit_logged("card_was_played", [card])
	
	
func _on_resolve_hand_requested() -> void:
	if effects_manager == null:
		return
	
	#process the card effects
	#either instantly or added to queue
	for card: Dictionary in DeckState.hand:
		for effect: Dictionary in card.get("effects_on_end", []):
			var e = effect.duplicate(true)
			e["instant"] = true
			effects_manager.handle_effect(e, {
				"card": card,
				"timing": "end"
			})

	DeckState.move_hand_to_discard()
	SignalBus.emit_logged("hand_resolved")

# -----------------------------------------------------------------------------
# 🏗 Structure resolution helpers
# -----------------------------------------------------------------------------
func _resolve_structure_request(card: Dictionary) -> Dictionary:
	if card.get("structure") != null:
		# Force cast to Dictionary, fallback to empty to satisfy the type checker
		var s: Dictionary = card.get("structure", {}) as Dictionary
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


func _resolve_structure_from_catalog(card: Dictionary) -> Dictionary:
	var info: Dictionary = DeckState.get_structure_info_from_card(card)
	var layer_name: String = info.get("layer", "")
	var source_name: String = info.get("source_name", "")
	var tile_name: String = info.get("tile_name", "")
	var cost: Dictionary = info.get("cost", {}) as Dictionary

	var resolved_source_id: int = -1
	var resolved_atlas: Vector2i = Vector2i(-1, -1)

	if source_name != "" and tile_name != "":
		var source_dict: Dictionary = CardCatalogue.catalog.get(layer_name, {}).get(source_name, {}) as Dictionary
		if not source_dict.is_empty():
			resolved_source_id = int(source_dict.get("source_id", -1))
			resolved_atlas = Vector2i(source_dict.get("tiles", {}).get(tile_name, Vector2i(-1, -1)))
			cost = source_dict.get("cost", cost) as Dictionary
		else:
			push_error("[DeckManager] Catalog entry not found for %s/%s" % [source_name, tile_name])

	elif card.has("source_id") and card.has("atlas_coords"):
		var sid: int = card.get("source_id", -1)
		var atlas: Vector2i = card.get("atlas_coords", Vector2i(-1, -1))
		for s_name: String in CardCatalogue.catalog.get(layer_name, {}).keys():
			var sd: Dictionary = CardCatalogue.catalog.get(layer_name, {}).get(s_name, {}) as Dictionary
			if int(sd.get("source_id", -9999)) == sid:
				source_name = s_name
				for t_name: String in sd.get("tiles", {}).keys():
					if Vector2i(sd.get("tiles", {}).get(t_name, Vector2i(-1, -1))) == atlas:
						tile_name = t_name
						break
				cost = sd.get("cost", cost) as Dictionary
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
		"amount": info.get("place_amount", 0),
		"cost": cost
	}
	
# -----------------------------------------------------------------------------
# ✨ Play‑phase effect delegation
# -----------------------------------------------------------------------------
func _run_on_play_effects(card: Dictionary) -> void:
	if effects_manager == null:
		return
	for effect: Dictionary in card.get("effects_on_play", []):
		var e = effect.duplicate(true)
		e["instant"] = true
		effects_manager.handle_effect(e, {
			"card": card,
			"timing": "play"
		})
