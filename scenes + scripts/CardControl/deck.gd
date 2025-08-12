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
			"on_play": func():
				print("Lumber Harvest played: +3 wood")
				resource_controller.add_wood(3),
		},

		{
			"name": "Foraging Party",
			"description": "Spend 1 population to gain 2 food.",
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
			"on_end": func():
				print("Stone Meditation resolved: +2 stone")
				resource_controller.add_stone(2),
		},

		{
			"name": "Idle Hands",
			"description": "Lose 1 population if left in hand.",
			"on_end": func():
				print("Idle Hands resolved: -1 population")
				resource_controller.add_pop(-1),
		},

		{
			"name": "Village Growth",
			"description": "Gain 2 population.",
			"on_play": func():
				print("Village Growth played: +2 population")
				resource_controller.add_pop(2),
		},

		{
			"name": "Campfire Cooking",
			"description": "Spend 2 wood to gain 3 food.",
			"on_play": func():
				if resource_controller.wood_count >= 2:
					print("Campfire Cooking played: -2 wood, +3 food")
					resource_controller.add_wood(-2)
					resource_controller.add_food(3)
				else:
					print("Campfire Cooking failed: not enough wood"),
		},
	]
