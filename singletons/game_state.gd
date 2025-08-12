extends Node
class_name GameState

# this singleton is to keep track of signals used throughout the game
# relating to turn and card phase (macro and micro)

# Game turn lifecycle (macro)
signal game_started
signal turn_ended(turn_number : int)
signal phase_changed(new_phase : String)
signal play_phase_ended

# Card system (micro)
signal hand_drawn(cards : Array)
signal card_played(card_data : Dictionary)
signal play_phase_state_changed(state : String)

# Grid system
signal tile_placed(tile_data : Dictionary)

# Resources
signal resource_updated(resource : String, amount : int)

var game_running : bool = false
var current_turn : int = 0
var current_phase : String = "None"
var play_phase_state : String = "Idle"  # sub-state within Play phase


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("advance_phase"):
		print("\n[DEBUG] Manual input received: advance_phase")
		print("[DEBUG] Current phase before advance: ", current_phase)
		print("[DEBUG] Current turn: ", current_turn)
		advance_phase()


# will trigger this manually from somewhere like a go button
func _ready() -> void:
	start_game()


func start_game():
	game_running = true
	current_turn = 1
	current_phase = "Play"
	play_phase_state = "Idle"
	call_deferred("_emit_game_started")


func _emit_game_started() -> void:
	print("\n[DEBUG] Game started")
	print("[DEBUG] Initial phase: ", current_phase)
	print("[DEBUG] Initial play phase state: ", play_phase_state)
	emit_signal("game_started")
	emit_signal("phase_changed", current_phase)
	emit_signal("play_phase_state_changed", play_phase_state)
	print("[DEBUG] All game setup complete")


func advance_phase():
	var previous_phase := current_phase
	match current_phase:
		"Play":
			current_phase = "Tile Effects"
		"Tile Effects":
			current_phase = "Resource Calculations"
		"Resource Calculations":
			end_turn()
			return
	print("\n[DEBUG] Phase advanced")
	print("[DEBUG] Previous phase: ", previous_phase)
	print("[DEBUG] New phase: ", current_phase)
	emit_signal("phase_changed", current_phase)


func end_turn():
	print("\n[DEBUG] Turn ended")
	print("[DEBUG] Turn number: ", current_turn)
	emit_signal("turn_ended", current_turn)
	current_turn += 1
	current_phase = "Play"
	play_phase_state = "Idle"
	print("[DEBUG] New turn: ", current_turn)
	print("[DEBUG] Phase reset to: ", current_phase)
	print("[DEBUG] Play phase state reset to: ", play_phase_state)
	emit_signal("phase_changed", current_phase)
	emit_signal("play_phase_state_changed", play_phase_state)


func set_play_phase_state(state: String) -> void:
	var previous_state := play_phase_state
	play_phase_state = state
	print("\n[DEBUG] Play phase state changed")
	print("[DEBUG] Previous state: ", previous_state)
	print("[DEBUG] New state: ", state)
	emit_signal("play_phase_state_changed", state)
