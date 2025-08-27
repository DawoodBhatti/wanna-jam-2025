extends Node

# -------------------------------------------------------------------
# 🗂 Card schema for reference / documentation
# -------------------------------------------------------------------
const CARD_SCHEMA: Dictionary = {
	"id": "unique_card_id",
	"name": "Card Name",
	"description": "What this card does in simple terms.",
	"cost": {},
	"effects_on_play": [], #TODO: include effect examples here...
	"effects_on_end": []
}
#TODO: it's possible to modify schema to include things like background types

# -------------------------------------------------------------------
# 📦 Data Stores
# -------------------------------------------------------------------
var deck: Array[Dictionary] = []
var build_catalogue: BuildCatalogue

# -------------------------------------------------------------------
# 🚦 Initialization
# -------------------------------------------------------------------
func _ready() -> void:
	build_catalogue = get_node("/root/BuildCatalogue")
	load_cards()

# -------------------------------------------------------------------
# ♠️ Deck Definition
# -------------------------------------------------------------------
func load_cards() -> void:
	deck = [
		{
			"id": "lumber_harvest",
			"name": "Lumber Harvest",
			"description": "Gain 3 wood.",
			"cost": {},
			"effects_on_play": [
				{ "type": "resource_change", "target": "wood", "amount": 3 }
			],
			"effects_on_end": []
		},
		{
			"id": "place_stone",
			"name": "Place Stone",
			"description": "Spend 1 stone to place a stone structure.",
			"cost": { "stone": 1 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "stone", "amount": -1 },
				{ "type": "placement", "tile_name": "StoneTile", "amount": 1  }
			],
			"effects_on_end": []
		},
		#{
			#"id": "medusa",
			#"name": "Medusa",
			#"description": "Turns surrounding ground to stone at end of turn.",
			#"cost": { "pop": 5 },
			#"structure_built": { "tile_name": "MedusaTile", "place_amount": 1 },
			#"effects_on_play": [
				#{ "type": "resource_change", "target": "pop", "amount": -5 },
				#{ "type": "enter_structure_placement" }
			#],
			#"effects_on_end": [
				#{ "type": "aoe_tile_transform", "target_tile": "StoneTile", "radius": 1 }
			#]
		#},
		{
			"id": "foraging_party",
			"name": "Foraging Party",
			"description": "Spend 1 population to gain 2 food.",
			"cost": { "pop": 1 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "pop", "amount": -1 },
				{ "type": "resource_change", "target": "food", "amount": 2 }
			],
			"effects_on_end": []
		},
		{
			"id": "stone_meditation",
			"name": "Stone Meditation",
			"description": "If unplayed, gain 2 stone at end of turn.",
			"cost": {},
			"effects_on_play": [],
			"effects_on_end": [
				{ "type": "resource_change", "target": "stone", "amount": 2 }
			]
		},
		{
			"id": "idle_hands",
			"name": "Idle Hands",
			"description": "Lose 1 population if left in hand.",
			"cost": {},
			"effects_on_play": [],
			"effects_on_end": [
				{ "type": "resource_change", "target": "pop", "amount": -1 }
			]
		},
		{
			"id": "village_growth",
			"name": "Village Growth",
			"description": "Gain 2 population.",
			"cost": { "food": 2 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "pop", "amount": 2 }
			],
			"effects_on_end": []
		},
		{
			"id": "campfire",
			"name": "Campfire",
			"description": "Spend 2 wood to gain 3 food.",
			"cost": { "wood": 2 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "wood", "amount": -2 },
				{ "type": "resource_change", "target": "food", "amount": 3 }
			],
			"effects_on_end": []
		},
		{
			"id": "stone_masonry",
			"name": "Stone Masonry",
			"description": "Spend 3 stone to gain 1 population.",
			"cost": { "stone": 3 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "stone", "amount": -3 },
				{ "type": "resource_change", "target": "pop", "amount": 1 }
			],
			"effects_on_end": []
		},
		{
			"id": "forest_fire",
			"name": "Forest Fire",
			"description": "Lose 2 wood. All players lose 1 population.",
			"cost": {},
			"effects_on_play": [
				{ "type": "resource_change", "target": "wood", "amount": -2 },
				{ "type": "resource_change", "target": "pop", "amount": -1 }
			],
			"effects_on_end": []
		},
		{
			"id": "scouting_party",
			"name": "Scouting Party",
			"description": "Spend 1 food to reveal 2 cards.",
			"cost": { "food": 1 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "food", "amount": -1 },
				{ "type": "draw_cards", "amount": 2 }
			],
			"effects_on_end": []
		},
		{
			"id": "wooden_barricade",
			"name": "Wooden Barricade",
			"description": "Spend 2 wood to prevent 1 population loss this turn.",
			"cost": { "wood": 2 },
			"effects_on_play": [
				{ "type": "resource_change", "target": "wood", "amount": -2 },
				{ "type": "flag", "name": "prevent_pop_loss", "value": true }
			],
			"effects_on_end": []
		},
		{
			"id": "recycle_structure",
			"name": "Recycle Structure",
			"description": "Enter recycle mode to reclaim stone.",
			"cost": {},
			"effects_on_play": [
				{ "type": "resource_change", "target": "stone", "amount": -1 },
				{ "type": "placement", "tile_name": "StoneTile", "amount": 1  }
			],
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
	var build_def: Dictionary = build_catalogue.get_tile(tile_name)
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
