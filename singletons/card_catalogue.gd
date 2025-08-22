extends Node

# 🗂 Card schema for reference / documentation
# --------------------------------------------------------------------------
const CARD_SCHEMA: Dictionary = {
	"id": "unique_card_id",
	"name": "Card Name",
	"description": "What this card does in simple terms.",
	"cost": {},
	"background_style": "theme_key",
	"builds_structure": false,
	"structure": null,
	"effects_on_play": [],
	"effects_on_end": []
}
#TODO: if we ever introduce duplicates into the deck then we introduce numbers into the ids, also.
# --------------------------------------------------------------------------

var deck: Array[Dictionary] = []
var catalog: Dictionary = {} # Structure metadata, e.g. source definitions and tile mappings

func _ready() -> void:
	load_cards()

func load_cards() -> void:
	deck = [
		{
			"id": "lumber_harvest",
			"name": "Lumber Harvest",
			"description": "Gain 3 wood.",
			"cost": {},
			"background_style": "wood",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "wood", "amount": 3 }
			],
			"effects_on_end": []
		},
		{
			"id": "foraging_party",
			"name": "Foraging Party",
			"description": "Spend 1 population to gain 2 food.",
			"cost": { "pop": 1 },
			"background_style": "food",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "pop", "amount": -1 },
				{ "type": "resource", "target": "food", "amount": 2 }
			],
			"effects_on_end": []
		},
		{
			"id": "stone_meditation",
			"name": "Stone Meditation",
			"description": "If unplayed, gain 2 stone at end of turn.",
			"cost": {},
			"background_style": "stone",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [],
			"effects_on_end": [
				{ "type": "resource", "target": "stone", "amount": 2 }
			]
		},
		{
			"id": "idle_hands",
			"name": "Idle Hands",
			"description": "Lose 1 population if left in hand.",
			"cost": {},
			"background_style": "warning",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [],
			"effects_on_end": [
				{ "type": "resource", "target": "pop", "amount": -1 }
			]
		},
		{
			"id": "village_growth",
			"name": "Village Growth",
			"description": "Gain 2 population.",
			"cost": { "food": 2 },
			"background_style": "population",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "pop", "amount": 2 }
			],
			"effects_on_end": []
		},
		{
			"id": "campfire",
			"name": "Campfire",
			"description": "Spend 2 wood to gain 3 food.",
			"cost": { "wood": 2 },
			"background_style": "food",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "wood", "amount": -2 },
				{ "type": "resource", "target": "food", "amount": 3 }
			],
			"effects_on_end": []
		},
		{
			"id": "stone_masonry",
			"name": "Stone Masonry",
			"description": "Spend 3 stone to gain 1 population.",
			"cost": { "stone": 3 },
			"background_style": "stone",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "stone", "amount": -3 },
				{ "type": "resource", "target": "pop", "amount": 1 }
			],
			"effects_on_end": []
		},
		{
			"id": "forest_fire",
			"name": "Forest Fire",
			"description": "Lose 2 wood. All players lose 1 population.",
			"cost": {},
			"background_style": "disaster",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "wood", "amount": -2 },
				{ "type": "resource", "target": "pop", "amount": -1 }
			],
			"effects_on_end": []
		},
		{
			"id": "scouting_party",
			"name": "Scouting Party",
			"description": "Spend 1 food to reveal 2 cards.",
			"cost": { "food": 1 },
			"background_style": "exploration",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "food", "amount": -1 },
				{ "type": "draw_cards", "amount": 2 }
			],
			"effects_on_end": []
		},
		{
			"id": "wooden_barricade",
			"name": "Wooden Barricade",
			"description": "Spend 2 wood to prevent 1 population loss this turn.",
			"cost": { "wood": 2 },
			"background_style": "defense",
			"builds_structure": false,
			"structure": null,
			"effects_on_play": [
				{ "type": "resource", "target": "wood", "amount": -2 },
				{ "type": "flag", "name": "prevent_pop_loss", "value": true }
			],
			"effects_on_end": []
		},
		{
			"id": "place_stone",
			"name": "Place Stone",
			"description": "Spend 1 stone to place a stone structure.",
			"cost": { "stone": 1 },
			"background_style": "stone",
			"builds_structure": true,
			"structure": {
				"layer": "StructuresLayer",
				"source_name": "Stone",
				"tile_name": "StoneTile",
				"place_amount": 1
			},
			"effects_on_play": [
				{ "type": "resource", "target": "stone", "amount": -1 },
				{ "type": "enter_structure_placement" }
			],
			"effects_on_end": []
		},
		{
			"id": "recycle_structure",
			"name": "Recycle Structure",
			"description": "Enter recycle mode to reclaim stone.",
			"cost": {},
			"background_style": "stone",
			"builds_structure": false,
			"structure": null
		},
		{
			"id": "medusa",
			"name": "Medusa",
			"description": "Turns surrounding ground to stone at end of turn.",
			"cost": { "pop": 5 },
			"background_style": "mythic",
			"builds_structure": true,
			"structure": {
				"layer": "StructuresLayer",
				"source_name": "Medusa",
				"tile_name": "MedusaTile",
				"place_amount": 1
			},
			"effects_on_play": [
				{ "type": "resource", "target": "pop", "amount": -5 },
				{ "type": "enter_structure_placement" }
			],
			"effects_on_end": [
				{ "type": "aoe_tile_transform", "target_tile": "StoneTile", "radius": 1 }
			]
		}
	]

#returns complete dictionary of all card info
func get_card_by_id(id: String) -> Dictionary:
	for card: Dictionary in deck:
		if card.get("id", "") == id:
			return card
	return {}

#TODO this function can be simplified/refactored because we should be querying the build catalogue and replacing the local source_dict
# take card ID and returns information about the structure to be placed
func resolve_structure_payload(card_id: String) -> Dictionary:
	var card: Dictionary = get_card_by_id(card_id)
	if card.is_empty():
		push_error("[CardCatalogue] Card not found: %s" % card_id)
		return {}

	var structure: Dictionary = card.get("structure", {}) as Dictionary
	if structure.is_empty():
		push_error("[CardCatalogue] Card missing structure block: %s" % card_id)
		return {}

	var layer: String = structure.get("layer", "")
	var source_name: String = structure.get("source_name", "")
	var tile_name: String = structure.get("tile_name", "")
	var place_amount: int = int(structure.get("place_amount", 1))
	var cost: Dictionary = card.get("cost", {}) as Dictionary

	var source_dict: Dictionary = catalog.get(layer, {}).get(source_name, {}) as Dictionary
	if source_dict.is_empty():
		push_error("[CardCatalogue] Missing source entry for %s/%s" % [layer, source_name])
		return {}

	var source_id: int = int(source_dict.get("source_id", -1))

	var atlas_coords_raw = source_dict.get("tiles", {}).get(tile_name)
	var atlas_coords: Vector2i = Vector2i(-1, -1)
	if typeof(atlas_coords_raw) == TYPE_VECTOR2I:
		atlas_coords = atlas_coords_raw

	if source_id < 0 or atlas_coords == Vector2i(-1, -1):
		push_error("[CardCatalogue] Invalid tile resolution for card: %s" % card.get("name", "unknown"))

	return {
		"layer": layer,
		"source_name": source_name,
		"tile_name": tile_name,
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"amount": place_amount,
		"cost": cost
	}
