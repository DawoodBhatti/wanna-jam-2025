extends Node

# -------------------------------------------------------------------
# 🗂 Card schema for reference / documentation
# -------------------------------------------------------------------
const CARD_SCHEMA: Dictionary = {
	"id": "unique_card_id",
	"name": "Card Name",
	"description": "What this card does in simple terms.",
	"cost": {},
	"instant_effects": [], #effects which occur instantly when card is played
	"end_turn_effects": [], #effects which occur at end of turn when a card
	"remain_effects": [] #effects which occur on turn end if card remains in hand
}

#TODO: it's possible to modify schema to include things like background types

# -------------------------------------------------------------------
# 📦 Data Stores
# -------------------------------------------------------------------
var deck: Array[Dictionary] = []

# -------------------------------------------------------------------
# 🚦 Initialization
# -------------------------------------------------------------------
func _ready() -> void:
	load_cards()

# -------------------------------------------------------------------
# ♠️ Deck Definition
# -------------------------------------------------------------------

func load_cards() -> void:
	deck = [
		{
			"id": "lumber_harvest",
			"name": "Lumber Harvest",
			"description": "Gain 1 wood instantly.",
			"cost": {},
			"instant_effects": [
				{ "type": "resource_change", "target": "wood", "amount": 1 }
			],
			"end_turn_effects": [],
			"remain_effects": []
		},
		{
			"id": "place_stone",
			"name": "Place Stone",
			"description": "Spend 1 stone to place a stone structure.",
			"cost": { "stone": 1 },
			"instant_effects": [
				{ "type": "resource_change", "target": "stone", "amount": -1 },
				{ "type": "placement", "tile_name": "StoneTile", "amount": 1 }
			],
			"end_turn_effects": [],
			"remain_effects": []
		},
		{
			"id": "foraging_party",
			"name": "Foraging Party",
			"description": "Spend 1 pop to gain 1 food.",
			"cost": { "pop": 1 },
			"instant_effects": [
				{ "type": "resource_change", "target": "pop", "amount": -1 },
				{ "type": "resource_change", "target": "food", "amount": 1 }
			],
			"end_turn_effects": [],
			"remain_effects": [
			]
		},
		{
			"id": "stone_meditation",
			"name": "Stone Meditation",
			"description": "If unplayed, gain 1 stone.",
			"cost": {},
			"instant_effects": [],
			"end_turn_effects": [],
			"remain_effects": [
				{ "type": "resource_change", "target": "stone", "amount": 1 },
			]
		},
				{
			"id": "medusa",
			"name": "Medusa",
			"description": "Place a tile which turns surrounding squares to stone on turn end.",
			"cost": {},
			"instant_effects": [
				{ "type": "resource_change", "target": "gold", "amount": 5},
				{ "type": "placement", "tile_name": "MedusaTile", "amount": 1 }

			],
			"end_turn_effects": [],
			"remain_effects": [],
		},
		{
			"id": "idle_hands",
			"name": "Idle Hands",
			"description": "Spend 1 wood or lose 1 pop.",
			"cost": {},
			"instant_effects": [
				{ "type": "resource_change", "target": "wood", "amount": 1 }
			],
			"end_turn_effects": [],
			"remain_effects": [
				{ "type": "resource_change", "target": "pop", "amount": -1 }
			]
		},
		{
			"id": "village_growth",
			"name": "Village Growth",
			"description": "Gain 1 at end of turn.",
			"cost": { "food": 1 },
			"instant_effects": [
			],
			"end_turn_effects": [
				{ "type": "resource_change", "target": "pop", "amount": 1 }
			],
			"remain_effects": []
		},
		{
			"id": "campfire",
			"name": "Campfire",
			"description": "Spend 1 wood to gain 2 food instantly.",
			"cost": { "wood": 1 },
			"instant_effects": [
				{ "type": "resource_change", "target": "wood", "amount": -1 },
				{ "type": "resource_change", "target": "food", "amount": 2 }
			],
			"end_turn_effects": [],
			"remain_effects": [
			]
		},
		{
			"id": "stone_masonry",
			"name": "Stone Masonry",
			"description": "Spend 1 stone to gain 1 wood at end of turn.",
			"cost": { "stone": 1 },
			"instant_effects": [
				{ "type": "resource_change", "target": "stone", "amount": -1 },
			],
			"end_turn_effects": [
				{ "type": "resource_change", "target": "wood", "amount": 1 }
			],
			"remain_effects": []
		},
		{
			"id": "forest_fire",
			"name": "Forest Fire",
			"description": "Spend 2 pop to prevent 5 wood loss if left in hand.",
			"cost": {},
			"instant_effects": [
				{ "type": "resource_change", "target": "pop", "amount": -2 }
			],
			"end_turn_effects": [
			],
			"remain_effects": [{ "type": "resource_change", "target": "pop", "amount": -5 }]
		},
		{
			"id": "scouting_party",
			"name": "Scouting Party",
			"description": "Spend 1 food ...",
			"cost": { "food": 1 },
			"instant_effects": [
				{ "type": "resource_change", "target": "food", "amount": -1 },
			],
			"end_turn_effects": [
			],
			"remain_effects": []
		},
		{
			"id": "wooden_barricade",
			"name": "Wooden Barricade",
			"description": "Spend 1 wood to gain 1 pop instantly.",
			"cost": { "wood": 1 },
			"instant_effects": [
				{ "type": "resource_change", "target": "wood", "amount": -1 },
				{ "type": "resource_change", "target": "pop", "amount": 1 }
			],
			"end_turn_effects": [],
			"remain_effects": [
			]
		},
		{
			"id": "recycle_structure",
			"name": "Recycle Structure",
			"description": "Remove 1 stone tile, gain 1 stone at end of turn.",
			"cost": {},
			"instant_effects": [
				{ "type": "removal", "tile_name": "StoneTile", "amount": 1 }
			],
			"end_turn_effects": [
				{ "type": "resource_change", "target": "stone", "amount": 1 },
			],
			"remain_effects": []
		},
		# --- Instant-only ---
		{
			"id": "quick_chop",
			"name": "Quick Chop",
			"description": "Gain 2 wood instantly.",
			"cost": {},
			"instant_effects": [
				{ "type": "resource_change", "target": "wood", "amount": 2 }
			],
			"end_turn_effects": [],
			"remain_effects": []
		},
		{
			"id": "stone_pick",
			"name": "Stone Pick",
			"description": "Gain 1 stone instantly.",
			"cost": {},
			"instant_effects": [
				{ "type": "resource_change", "target": "stone", "amount": 1 }
			],
			"end_turn_effects": [],
			"remain_effects": []
		},

		# --- End-turn-only ---
		{
			"id": "harvest_festival",
			"name": "Harvest Festival",
			"description": "At end of turn, gain 1 food.",
			"cost": {},
			"instant_effects": [],
			"end_turn_effects": [
				{ "type": "resource_change", "target": "food", "amount": 1 }
			],
			"remain_effects": []
		},
		{
			"id": "stone_settle",
			"name": "Stone Settle",
			"description": "At end of turn, place 1 stone structure.",
			"cost": {},
			"instant_effects": [],
			"end_turn_effects": [
				{ "type": "placement", "tile_name": "StoneTile", "amount": 1 }
			],
			"remain_effects": []
		},

		# --- Remain-only ---
		{
			"id": "forgotten_supplies",
			"name": "Forgotten Supplies",
			"description": "If unplayed, gain 1 wood.",
			"cost": {},
			"instant_effects": [],
			"end_turn_effects": [],
			"remain_effects": [
				{ "type": "resource_change", "target": "wood", "amount": 1 }
			]
		},
		{
			"id": "neglected_tools",
			"name": "Neglected Tools",
			"description": "If unplayed, lose 1 stone.",
			"cost": {},
			"instant_effects": [],
			"end_turn_effects": [],
			"remain_effects": [
				{ "type": "resource_change", "target": "stone", "amount": -1 }
			]
		}
	]

# -------------------------------------------------------------------
# 🔍 Lookup Helpers
# -------------------------------------------------------------------
func get_card_by_id(id: String) -> Dictionary:
	for card: Dictionary in deck:
		if card.get("id", "") == id:
			return card
	return {}

# -------------------------------------------------------------------
# 🏗️ Structure Payload Resolution
# -------------------------------------------------------------------
func resolve_structure_payload(card_id: String) -> Dictionary[String, Variant]:
	var card: Dictionary = get_card_by_id(card_id)
	if card.is_empty():
		push_error("[CardCatalogue] Card not found: %s" % card_id)
		return {}

	var structure_built: Dictionary = card.get("structure_built", {}) as Dictionary
	if structure_built.is_empty():
		push_error("[CardCatalogue] Card missing structure_built: %s" % card_id)
		return {}

	var tile_name: String = structure_built.get("tile_name", "") as String
	var build_def: Dictionary = TileCatalogue.get_tile(tile_name)
	if build_def.is_empty():
		push_error("[CardCatalogue] Missing build definition for tile: %s" % tile_name)
		return {}

	return {
		"layer": build_def.get("build_layer", "") as String,
		"tile_name": tile_name,
		"source_id": int(build_def.get("source_id", -1)),
		"atlas_coords": build_def.get("tiles", [])[0] as Vector2i,
		"amount": int(structure_built.get("place_amount", 1)),
		"cost": card.get("cost", {}) as Dictionary
	}
