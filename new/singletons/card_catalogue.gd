extends Node

# 🗂 Card schema for reference / documentation
# --------------------------------------------------------------------------
# This schema describes the shape of a card entry in the catalog.
# --------------------------------------------------------------------------

const CARD_SCHEMA := {
	# 📇 Unique identifier for internal lookups (no spaces, lowercase, underscores)
	"id": "unique_card_id",

	# 🏷 Display name shown to players
	"name": "Card Name",

	# 📜 Short description of the card’s effect (appears on card face / tooltips)
	"description": "What this card does in simple terms.",

	# 💰 Resource cost to play the card
	# Always a dictionary: omit keys for unused resources
	# e.g., { "wood": 2, "food": 1 } or {} for zero cost
	"cost": { },

	# 🎨 Visual styling for the card background (links to your theme system)
	# e.g., "wood", "food", "stone", "mythic"
	"background_style": "theme_key",

	# 🏗 Structure placement flag — does playing this card initiate building?
	"builds_structure": false, # true if this card places a structure

	# 🗂 Structure metadata (only used if builds_structure = true)
	#   layer        → Which tilemap/layer to place on
	#   source_name  → Name of the structure source/preset in the catalog
	#   tile_name    → Name of the tile variant to place
	#   place_amount → How many tiles/structures to place
	"structure": null, # or { "layer": "...", "source_name": "...", "tile_name": "...", "place_amount": 1 }

	# 🎯 List of effects triggered when the card is played immediately
	# Each effect is a dictionary with:
	#   type     → what kind of effect this is (e.g. "resource", "draw_cards", "flag", "enter_structure_placement")
	#   target   → resource/flag/other target (if applicable)
	#   amount   → integer change (if applicable)
	#   name/value → for flags or booleans
	"effects_on_play": [
		# Example: { "type": "resource", "target": "wood", "amount": 3 }
	],

	# ⏳ List of effects triggered at the end of turn if the card was unplayed or remains active
	"effects_on_end": [
		# Example: { "type": "resource", "target": "stone", "amount": 2 }
	]
}

# --------------------------------------------------------------------------

var deck: Array[Dictionary] = []

func _ready() -> void:
	load_cards()

func load_cards() -> void:
	deck = [
		{
			"id": "lumber_harvest",
			"name": "Lumber Harvest",
			"description": "Gain 3 wood.",
			"cost": { },
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
			"cost": { },
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
			"cost": { },
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
			"cost": { },
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
			"cost": { },
			"background_style": "stone",
			"builds_structure": false,
			"structure": null        },
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
