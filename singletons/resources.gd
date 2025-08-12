extends Node

# Signals tell interested nodes that a specific resource changed
signal stone_changed(amount: int)
signal wood_changed(amount: int)
signal food_changed(amount: int)
signal pop_changed(amount: int)

var stone_count: int = 0
var wood_count: int = 0
var food_count: int = 0
var pop_count: int = 0


# --- Public API ---
func add_stone(amount: int) -> void:
	stone_count += amount
	stone_changed.emit(amount)


func add_wood(amount: int) -> void:
	wood_count += amount
	wood_changed.emit(amount)


func add_food(amount: int) -> void:
	food_count += amount
	food_changed.emit(amount)


func add_pop(amount: int) -> void:
	pop_count += amount
	pop_changed.emit(amount)


# --- Debug helper ---
func test_random_resource_change() -> void:
	var funcs = [add_stone, add_wood, add_food, add_pop]
	var resource_names = ["STONE", "WOOD", "FOOD", "POP"]
	var index = randi() % funcs.size()
	var amount = randi() % 21 - 4  # -4..16

	print("")
	print("=== TEST RESOURCE CHANGE ===")
	print("Chosen: %s | Amount: %d" % [resource_names[index], amount])

	funcs[index].call(amount)

	# Print all current totals for quick reference
	print("Current totals → Stone:%d  Wood:%d  Food:%d  Pop:%d"
		% [stone_count, wood_count, food_count, pop_count])
	print("============================\n")


# --- Input handling ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test_resource_change"):
		test_random_resource_change()
