extends Node2D
class_name DeckManager
var effects_manager : Node2D

# -----------------------------------------------------------------------------
# 🃏 DeckManager — Card lifecycle controller
#
# RESPONSIBILITIES:
# • Owns the lifecycle of cards from draw → play → discard within the "Play" phase.
# • Listens for high-level phase and card click events via SignalBus.
# • Delegates effect execution to EffectsManager — never runs effects itself.
# • During end-of-turn, enqueues "effects_on_end" for cards left in hand.
# • Resolves structure placement requests from card data (preferring inline structure
#   definitions from the catalog; falling back to catalogue lookups when needed).
#
# KEY INTERACTIONS:
# • Signals to GameState/SignalBus when:
#   - Cards are drawn, played, discarded
#   - Play sub‑phase changes (Drawing / Playing / Resolving / etc.)
#   - Structure or recycle modes are requested
# • Works alongside EffectsManager:
#   - Passes effects with explicit `instant=true` (play‑phase) or `instant=false` (end‑phase)
#   - Leaves queue processing to EffectsManager / GameState signalling
# • Cooperates with DeckState to maintain deck, hand, and discard piles.
#
# PHASE FLOW IT HANDLES:
#   Play phase:
#     1. Drawing: pulls new cards into hand.
#     2. Playing: responds to card clicks, enforces build/recycle rules,
#        and delegates effect execution.
#     3. Resolving: processes unplayed cards' end effects, moves them to discard.
# -----------------------------------------------------------------------------

func _ready() -> void:
	
	
	effects_manager = get_node("../EffectsManager")
	
	if DeckState.deck.is_empty():
		DeckState.deck.append_array(CardCatalogue.deck.duplicate(true))
		DeckState.shuffle_deck()

	
	SignalBus.connect("phase_changed", Callable(self, "_on_phase_changed"))
	SignalBus.connect("card_clicked", Callable(self, "_on_card_clicked"))

	print("[DeckManager] ready!")

# In DeckManager.gd
func get_card_template() -> Control:
	return $CardTemplate

# -------------------------
# Phase orchestration
# -------------------------
func end_turn() -> void:
	_resolve_hand()

func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "Play":
		_start_play_cycle()

func _start_play_cycle() -> void:
	SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_DRAWING])
	var drawn: Array = DeckState.draw_from_deck(2)
	SignalBus.emit_logged("hand_drawn", [drawn])
	SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_PLAYING])

# -------------------------
# Card click/play handling
# -------------------------
func _on_card_clicked(card_data: Dictionary) -> void:
	if GameState.play_phase_state != GameState.PLAY_PHASE_STATE_PLAYING:
		return
	if not DeckState.hand.has(card_data):
		return

	_play_card_with_rules(card_data)

	if DeckState.hand.is_empty():
		_resolve_hand()

func _play_card_with_rules(card: Dictionary) -> void:
	# Make intention explicit (avoid “truthy default” reading).
	var builds_structure: bool = bool(card.get("builds_structure", false))
	var recycle_mode: bool = bool(card.get("recycle_mode", false))

	if builds_structure:
		SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_PLACING_STRUCTURE])

		var req: Dictionary = _resolve_structure_request(card)

		# Be explicit about affordability; avoid inline negations that hide intent.
		var cost: Dictionary = req.get("cost", {})
		var can_afford: bool = DeckState.can_afford(cost)
		if not can_afford:
			print("Not enough resources for %s" % card.get("name", "unknown"))
			SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_PLAYING])
			return

		# Effects route through EffectsManager; 'instant' flag decides execution path.
		_run_on_play_effects(card)

		SignalBus.emit_logged("structure_placement_requested", [req])
		SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_PLAYING])

	elif recycle_mode:
		SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_RECYCLE])

		_run_on_play_effects(card)

		SignalBus.emit_logged("recycle_mode_requested", [{ "amount": int(card.get("remove_amount", 1)) }])
		SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_PLAYING])

	else:
		_run_on_play_effects(card)

	DeckState.move_card_to_discard(card)
	SignalBus.emit_logged("card_played", [card])

# -------------------------
# Structure request resolution
# -------------------------
# Fallback lookup when card doesn't have inline 'structure' metadata.
# Tries two paths:
#   1. Layer/source_name/tile_name from card
#   2. source_id/atlas_coords from card
func _resolve_structure_from_catalog(card: Dictionary) -> Dictionary:
	var info: Dictionary = DeckState.get_structure_info_from_card(card)
	var layer_name: String = info.layer
	var source_name: String = info.source_name
	var tile_name: String = info.tile_name
	var cost: Dictionary = info.cost

	var resolved_source_id: int = -1
	var resolved_atlas: Vector2i = Vector2i(-1, -1)

	# --- Path 1: explicit catalog keys provided on the card ---
	if source_name != "" and tile_name != "":
		var source_dict: Dictionary = CardCatalogue.catalog.get(layer_name, {}).get(source_name, {}) as Dictionary
		if not source_dict.is_empty():
			resolved_source_id = int(source_dict.get("source_id", -1))
			resolved_atlas = Vector2i(source_dict.get("tiles", {}).get(tile_name, Vector2i(-1, -1)))
			cost = Dictionary(source_dict.get("cost", cost))
		else:
			push_error("[DeckManager] Catalog entry not found for %s/%s" % [source_name, tile_name])

	# --- Path 2: raw IDs present on the card ---
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

	# --- Sentinel check ---
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
		# Inline metadata path
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

	# Fallback to catalog-based resolution
	return _resolve_structure_from_catalog(card)

# -------------------------
# Hand Resolution
# -------------------------
func _resolve_hand() -> void:
	if effects_manager == null:
		return

	SignalBus.emit_logged("play_phase_state_changed", [GameState.PLAY_PHASE_STATE_RESOLVING])

	for card: Dictionary in DeckState.hand:
		for effect: Dictionary in card.get("effects_on_end", []):
			var e = effect.duplicate(true)
			e["instant"] = false
			effects_manager.handle_effect(e, { "card": card, "timing": "end" })

	DeckState.move_hand_to_discard()

	# Instead of directly calling effects_manager.run_end_turn_effects()
	SignalBus.emit_logged("hand_resolved")
	
	
# -------------------------
# Effect delegation
# -------------------------
func _run_on_play_effects(card: Dictionary) -> void:
	if effects_manager == null:
		return
	for effect: Dictionary in card.get("effects_on_play", []):
		var e = effect.duplicate(true)
		e["instant"] = true   # Play-phase effects always instant
		effects_manager.handle_effect(e, { "card": card, "timing": "play" })
