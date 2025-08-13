extends Node2D

#here we will define our cards for use in the game!
var deck: Array = []

@onready var resource_controller: Node = get_node("/root/Resources")  # Autoload singleton


func _ready() -> void:
	load_example_cards()


func load_example_cards() -> void:
	deck = [
	{
		"name": "Lumber Harvest",
		"description": "Gain 3 wood.",
		"cost": 0,
		"image_path": "",
		"background_style": "wood",
		"on_play": func():
			print("Lumber Harvest played: +3 wood")
			resource_controller.add_wood(3),
	},

	{
		"name": "Foraging Party",
		"description": "Spend 1 population to gain 2 food.",
		"cost": 0,
		"image_path": "",
		"background_style": "food",
		"on_play": func():
			if resource_controller.pop_count >= 1:
				print("Foraging Party played: -1 population, +2 food")
				resource_controller.add_pop(-1)
				resource_controller.add_food(2)
			else:
				print("Foraging Party failed: not enough population"),
	},

	{
		"name": "Stone Meditation",
		"description": "If unplayed, gain 2 stone at end of turn.",
		"cost": 0,
		"image_path": "",
		"background_style": "stone",
		"on_end": func():
			print("Stone Meditation resolved: +2 stone")
			resource_controller.add_stone(2),
	},

	{
		"name": "Idle Hands",
		"description": "Lose 1 population if left in hand.",
		"cost": 0,
		"image_path": "",
		"background_style": "warning",
		"on_end": func():
			print("Idle Hands resolved: -1 population")
			resource_controller.add_pop(-1),
	},

	{
		"name": "Village Growth",
		"description": "Gain 2 population.",
		"cost": { "food": 2 },
		"image_path": "",
		"background_style": "population",
		"on_play": func():
			if resource_controller.food_count >= 2:
				print("Village Growth played: -2 food, +2 population")
				resource_controller.add_food(-2)
				resource_controller.add_pop(2)
			else:
				print("Village Growth failed: not enough food"),
	},

	{
		"name": "Campfire",
		"description": "Spend 2 wood to gain 3 food.",
		"cost": { "wood": 2 },
		"image_path": "",
		"background_style": "food",
		"on_play": func():
			if resource_controller.wood_count >= 2:
				print("Campfire Cooking played: -2 wood, +3 food")
				resource_controller.add_wood(-2)
				resource_controller.add_food(3)
			else:
				print("Campfire Cooking failed: not enough wood"),
	},

	{
		"name": "Stone Masonry",
		"description": "Spend 3 stone to gain 1 population.",
		"cost": { "stone": 3 },
		"image_path": "",
		"background_style": "stone",
		"on_play": func():
			if resource_controller.stone_count >= 3:
				print("Stone Masonry played: -3 stone, +1 population")
				resource_controller.add_stone(-3)
				resource_controller.add_pop(1)
			else:
				print("Stone Masonry failed: not enough stone"),
	},

	{
		"name": "Forest Fire",
		"description": "Lose 2 wood. All players lose 1 population.",
		"cost": 0,
		"image_path": "",
		"background_style": "disaster",
		"on_play": func():
			print("Forest Fire played: -2 wood, -1 population")
			resource_controller.add_wood(-2)
			resource_controller.add_pop(-1),
	},

	{
		"name": "Scouting Party",
		"description": "Spend 1 food to reveal 2 cards.",
		"cost": { "food": 1 },
		"image_path": "",
		"background_style": "exploration",
		"on_play": func():
			if resource_controller.food_count >= 1:
				print("Scouting Party played: -1 food, reveal 2 cards")
				resource_controller.add_food(-1)
				# placeholder for draw logic
			else:
				print("Scouting Party failed: not enough food"),
	},

	{
		"name": "Wooden Barricade",
		"description": "Spend 2 wood to prevent 1 population loss this turn.",
		"cost": { "wood": 2 },
		"image_path": "",
		"background_style": "defense",
		"on_play": func():
			if resource_controller.wood_count >= 2:
				print("Wooden Barricade played: -2 wood, population loss prevented")
				resource_controller.add_wood(-2)
				# placeholder for effect flag
			else:
				print("Wooden Barricade failed: not enough wood"),
	},
]
