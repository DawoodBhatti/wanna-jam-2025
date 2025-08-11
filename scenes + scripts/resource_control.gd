extends Node2D

#TODO should this become a singleton?


#also possible to emit signals with arguments
signal stone_changed(amount: int)
signal wood_changed(amount: int)
signal food_changed(amount: int)
signal pop_changed(amount: int)

var stone_count : int = 0
var wood_count : int = 0
var food_count : int = 0
var pop_count : int = 0

@onready var stone_label: Label = get_node("../HUD/ResourceDisplay/HBoxContainer/StoneCount")
@onready var wood_label: Label = get_node("../HUD/ResourceDisplay/HBoxContainer/WoodCount")
@onready var food_label: Label = get_node("../HUD/ResourceDisplay/HBoxContainer/FoodCount")
@onready var pop_label: Label = get_node("../HUD/ResourceDisplay/HBoxContainer/PopCount")


func _ready() -> void:
	print("press f to test a random resource change \n")
	print("initial resources: ")
	print("stone: ", stone_count)
	print("wood: ", wood_count)
	print("wood: ", food_count)
	print("population: ", pop_count)
	
	
	stone_changed.connect(stone_change)
	wood_changed.connect(wood_change)
	food_changed.connect(food_change)
	pop_changed.connect(pop_change)
	

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		print("f key was pressed")
		test_random_resource_change()

func stone_change(amount):
	stone_count += amount
	stone_label.text = str(stone_count)


func wood_change(amount):
	wood_count += amount
	wood_label.text = str(wood_count)


func food_change(amount):
	food_count += amount
	food_label.text = str(food_count)

	
func pop_change(amount):
	pop_count += amount
	pop_label.text = str(pop_count)

	
func test_random_resource_change() -> void:
	var signals = ["stone_changed", "wood_changed", "food_changed", "pop_changed"]
	var chosen_signal = signals[randi() % signals.size()]
	var amount = randi() % 21 - 4  # restrict integer to between 0 and 20 and subtract 4 resulting in random number between -4 and +16
	print("Emitting signal: ", chosen_signal, " with amount: ", amount)
	emit_signal(chosen_signal, amount)
