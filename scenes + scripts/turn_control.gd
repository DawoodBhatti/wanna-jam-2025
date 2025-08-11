extends Node2D

# here we control the turn logic:

# start game (await signal from GameState singleton?)
# play cards
# end turn
# tile effects
# resource calculations
# increase turn count
# next turn?

# these are our 'phases': 
# play cards, tile effects, resource calculations

var game_running: bool = false
var turn_phase : Array = ["None", "Play", "Tile Effects", "Resource Calculations"]
var current_phase_index: int = 0
var turn_count: int = 0


signal Play
signal Tile_Effects
signal Resource_Calculations


func _ready() -> void:
	print("turn control running")
	print("game started: ", game_running)
	print("press H to manually advance phase \n")
	
	# optional: start game immediately for testing
	game_start()


# start game (await signal from GameState singleton)
func game_start() -> void:
	game_running = true
	current_phase_index = 1  # skip "None", start at "Play"
	print("Game started. Turn: ", turn_count)
	start_phase(turn_phase[current_phase_index])


# play cards
# tile effects
# resource calculations
func start_phase(phase_name: String) -> void:
	match phase_name:
		"Play":
			print("Phase: Play")
			emit_signal("Play")
		"Tile Effects":
			print("Phase: Tile Effects")
			emit_signal("Tile_Effects")
		"Resource Calculations":
			print("Phase: Resource Calculations")
			emit_signal("Resource_Calculations")


# end turn
# increase turn count
# next turn?
func advance_phase() -> void:
	current_phase_index += 1
	if current_phase_index >= turn_phase.size():
		end_turn()
	else:
		start_phase(turn_phase[current_phase_index])


func end_turn() -> void:
	print("Turn ", turn_count, " ended. \n")
	turn_count += 1
	current_phase_index = 1  # restart at "Play"
	start_phase(turn_phase[current_phase_index])


# manual input to trigger phase change
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_H:
				print("Manual phase advance triggered")
				advance_phase()
