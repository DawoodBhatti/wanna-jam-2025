extends Node

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var resources: Dictionary = {} # Injected from ResourceState or GameState

# -----------------
# Pure pile operations
# -----------------
func shuffle_deck() -> void:
	deck.shuffle()
	_broadcast_piles()

func draw_from_deck(count: int) -> Array[Dictionary]:
	var drawn: Array[Dictionary] = []
	for _i in count:
		if deck.is_empty():
			if discard_pile.is_empty():
				break
			deck = discard_pile
			discard_pile = []
			deck.shuffle()
		drawn.append(deck.pop_front())
	hand.append_array(drawn)
	_broadcast_piles()
	return drawn

func move_card_to_discard(card: Dictionary) -> void:
	hand.erase(card)
	discard_pile.append(card)
	_broadcast_piles()

func move_hand_to_discard() -> void:
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
	# Returns only what’s on the card, no external lookups
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
