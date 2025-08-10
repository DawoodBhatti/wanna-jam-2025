extends Node2D

var stone_count : int = 0
var wood_count : int = 0
var food_count : int = 0
var pop_count : int = 0

func _ready() -> void:
	print("initial resources: ")
	print("stone: ", stone_count)
	print("wood: ", wood_count)
	print("wood: ", food_count)
	print("population: ", pop_count)
