extends Node

const HAND_SIZE := 5

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var resources: Dictionary = {} # Injected from ResourceState or GameState
var debug_switch: bool = true

# -----------------
# Lifecycle / Setup
# -----------------

func _ready() -> void:
	init_from_catalogue()

func init_from_catalogue() -> void:
	if deck.is_empty():
		deck.append_array(CardCatalogue.deck.duplicate(true))
		shuffle_deck()

# -----------------
# Pure pile operations
# -----------------
func shuffle_deck() -> void:
	if debug_switch:
		print("[DeckState] shuffling deck")
	deck.shuffle()
	_broadcast_piles()

func draw_full_hand() -> void:
	if debug_switch:
		print("[DeckState] drawing full hand (%d cards)" % HAND_SIZE)
	_draw_and_emit(HAND_SIZE)

func draw_from_deck(count: int) -> void:
	if debug_switch:
		print("[DeckState] drawing %d card(s)" % count)
	_draw_and_emit(count)

func _draw_and_emit(count: int) -> void:
	if deck.is_empty() and not discard_pile.is_empty():
		_refill_deck_from_discard()

	var drawn: Array[Dictionary] = []
	for _i in count:
		if deck.is_empty():
			if discard_pile.is_empty():
				break
			_refill_deck_from_discard()
			if deck.is_empty():
				break
		drawn.append(deck.pop_front())

	hand.append_array(drawn)
	_broadcast_piles()
	SignalBus.emit_logged("hand_drawn", [drawn])

func _refill_deck_from_discard() -> void:
	if debug_switch:
		print("[DeckState] reshuffling discard into deck (%d cards)" % discard_pile.size())
	deck.append_array(discard_pile)
	discard_pile.clear()
	deck.shuffle()

func move_card_to_discard(card: Dictionary) -> void:
	if debug_switch:
		print("[DeckState] moving card: %s to discard" % str(card.get("name", "unknown")))
	hand.erase(card)
	discard_pile.append(card)
	_broadcast_piles()

func move_hand_to_discard() -> void:
	if debug_switch:
		print("[DeckState] moving hand to discard")
	discard_pile.append_array(hand)
	hand.clear()
	_broadcast_piles()

func get_pile_sizes() -> Dictionary:
	return {
		"deck": deck.size(),
		"hand": hand.size(),
		"discard": discard_pile.size()
	}

func can_afford(cost: Dictionary) -> bool:
	if cost.is_empty() or resources.is_empty():
		return true
	for res in cost.keys():
		if int(cost[res]) > resources.get(res, 0):
			return false
	return true

func get_structure_info_from_card(card: Dictionary) -> Dictionary:
	return {
		"layer": card.get("layer", "StructuresLayer"),
		"source_name": card.get("source_name", ""),
		"tile_name": card.get("tile_name", ""),
		"place_amount": card.get("place_amount", 1),
		"cost": card.get("cost", {})
	}

func _broadcast_piles() -> void:
	SignalBus.emit_logged("piles_changed", [
		deck.size(), hand.size(), discard_pile.size()
	])
