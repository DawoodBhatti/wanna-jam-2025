extends Node
class_name GameState

# -----------------
# Signals
# -----------------
signal game_started
signal turn_ended(turn_number: int)
signal phase_changed(new_phase: String)
signal hand_drawn(cards: Array) # could rename to hand_updated
signal card_played(card_data: Dictionary)
signal play_phase_state_changed(state: String)
signal piles_changed(deck_size: int, hand_size: int, discard_size: int)
signal recycle_mode_requested(data: Dictionary)
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
# References
# -----------------
var structure_manager: StructureManager
var resources: Node # GameResources singleton

# -----------------
# Lifecycle
# -----------------
func _ready() -> void:
	print("[GameState] Ready")

	structure_manager = get_node("/root/main/StructureManager") as StructureManager
	if structure_manager:
		structure_manager.connect("tile_effects_done", Callable(self, "_on_tile_effects_done"))

	resources = get_node_or_null("/root/GameResources")
	if resources == null:
		push_warning("[GameState] GameResources singleton not found — resource checks disabled")

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
	emit_signal("cancel_active_modes")

	match current_phase:
		"Play":
			resolve_hand()
			current_phase = "Tile Effects"
			emit_signal("phase_changed", current_phase)
			if structure_manager:
				structure_manager.run_tile_effects_phase()
			else:
				push_warning("No StructureManager to run tile effects — skipping")
				_on_tile_effects_done()

		"Tile Effects":
			print("[GameState] Advancing from Tile Effects → Play (next turn)")
			current_turn += 1
			emit_signal("turn_ended", current_turn - 1)
			current_phase = "Play"
			emit_signal("phase_changed", current_phase)

# -----------------
# Phase callbacks
# -----------------
func _on_tile_effects_done() -> void:
	print("[GameState] Tile Effects phase complete — advancing")
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

	for _i in count:
		if deck.is_empty():
			if discard_pile.is_empty():
				break
			deck = discard_pile
			discard_pile = []
			deck.shuffle()
		var card: Dictionary = deck.pop_front()
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

	var builds_structure: bool = bool(card.get("builds_structure", false))
	var is_recycle: bool = bool(card.get("recycle_mode", false))

	if builds_structure:
		var req: Dictionary = _build_structure_request_from_card(card)
		var cost: Dictionary = req.get("cost", {})

		print("[ReqFromCard]",
			"layer=", req.get("layer", ""),
			"source=", req.get("source_name", ""),
			"tile=", req.get("tile_name", ""),
			"src_id=", req.get("source_id", -1),
			"atlas=", req.get("atlas_coords", Vector2i(-1, -1))
		)


		if not _can_afford(cost):
			print("[GameState] Not enough resources to play card: %s" % card.get("name", ""))
			set_play_phase_state(PLAY_PHASE_STATE_IDLE)
			return

		if card.has("on_play"):
			card["on_play"].call()

		set_play_phase_state(PLAY_PHASE_STATE_PLACING_STRUCTURE)
		emit_signal("structure_placement_requested", req)

	elif is_recycle:
		if card.has("on_play"):
			card["on_play"].call()

		set_play_phase_state(PLAY_PHASE_STATE_RECYCLE)
		emit_signal("recycle_mode_requested", {
			"amount": int(card.get("remove_amount", 1))
		})

	else:
		if card.has("on_play"):
			card["on_play"].call()
		set_play_phase_state(PLAY_PHASE_STATE_IDLE)

	emit_signal("card_played", card)
	print("Played card: ", card.get("name", ""))
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

# -----------------
# Catalog + resource helpers
# -----------------
func _build_structure_request_from_card(card: Dictionary) -> Dictionary:
	var layer_name: String = card.get("layer", "StructuresLayer") as String
	var source_name: String = card.get("source_name", "") as String
	var tile_name: String = card.get("tile_name", "") as String
	var amount: int = card.get("place_amount", 1) as int

	var cost: Dictionary = {}
	var resolved_source_id: int = -1
	var resolved_atlas: Vector2i = Vector2i(-1, -1)

	# ✅ Preferred: resolve entirely from names via Catalog
	if source_name != "" and tile_name != "":
		var source_dict: Dictionary = Catalog.catalog.get(layer_name, {}).get(source_name, {}) as Dictionary
		if not source_dict.is_empty():
			resolved_source_id = int(source_dict.get("source_id", -1))
			resolved_atlas = Vector2i(source_dict.get("tiles", {}).get(tile_name, Vector2i(-1, -1)))
			cost = Dictionary(source_dict.get("cost", card.get("cost", {})))
		else:
			push_error("[GameState] Catalog entry not found for %s/%s" % [source_name, tile_name])

	# ⚠️ Optional Fallback: reverse-lookup from IDs in card
	elif card.has("source_id") and card.has("atlas_coords"):
		var sid: int = card.get("source_id", -1) as int
		var atlas: Vector2i = card.get("atlas_coords", Vector2i(-1, -1)) as Vector2i
		for s_name: String in Catalog.catalog.get(layer_name, {}).keys():
			var sd: Dictionary = Catalog.catalog[layer_name][s_name]
			if int(sd.get("source_id", -9999)) == sid:
				source_name = s_name
				for t_name: String in sd.get("tiles", {}).keys():
					if Vector2i(sd["tiles"][t_name]) == atlas:
						tile_name = t_name
						break
				cost = Dictionary(sd.get("cost", card.get("cost", {})))
				resolved_source_id = sid
				resolved_atlas = atlas
				break

	# 🛑 Fail loud if nothing valid
	if resolved_source_id < 0 or resolved_atlas == Vector2i(-1, -1):
		push_error("[GameState] Could not resolve valid tile for card: %s" % card.get("name", ""))

	return {
		"layer": layer_name,
		"source_name": source_name,
		"tile_name": tile_name,
		"source_id": resolved_source_id,
		"atlas_coords": resolved_atlas,
		"amount": amount,
		"cost": cost
	}


func _can_afford(cost: Dictionary) -> bool:
	if cost.is_empty() or resources == null:
		return true

	for res in cost.keys():
		var needed: int = int(cost[res])
		if needed > 0 and _get_resource_amount(String(res)) < needed:
			return false
	return true

func _get_resource_amount(res: String) -> int:
	if resources == null:
		return 0
	match res:
		"stone":
			return int(resources.stone_count)
		"wood":
			return int(resources.wood_count)
		"food":
			return int(resources.food_count)
		"pop":
			return int(resources.pop_count)
		_:
			return 0
