extends Node2D

#also possible to emit signals with arguments
signal stone_changed(amount: int)
signal wood_changed(amount: int)
signal food_changed(amount: int)
signal pop_changed(amount: int)


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
	
	stone_changed.connect(stone_change)	
	wood_changed.connect(wood_change)	
	food_changed.connect(food_change)	
	pop_changed.connect(pop_change)

func stone_change(amount):
	stone_count += amount

func wood_change(amount):
	stone_count += amount

func food_change(amount):
	stone_count += amount
	
func pop_change(amount):
	stone_count += amount
