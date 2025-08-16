extends Node

# ----------------------------
# 🪵 Resource Signals
# ----------------------------
signal stone_changed(amount: int)
signal wood_changed(amount: int)
signal food_changed(amount: int)
signal pop_changed(amount: int)

# ----------------------------
# 🎮 Game Flow Signals
# ----------------------------
signal game_started
signal turn_ended(turn_number: int)
signal phase_changed(new_phase: String)
signal play_phase_state_changed(state: String)
signal cancel_active_modes

# ----------------------------
# 🃏 Card & Hand Signals
# ----------------------------
signal hand_drawn(cards: Array)
signal card_played(card_data: Dictionary)
signal card_clicked(card_data: Dictionary)
signal piles_changed(deck_size: int, hand_size: int, discard_size: int)

# ----------------------------
# 🏗️ Structure & Tile Signals
# ----------------------------
signal structure_placement_requested(structure_info: Dictionary)
signal structure_placed(data)
signal structure_recycled(data)
signal tile_effects_done
signal recycle_mode_requested(data: Dictionary)

# ----------------------------
# 🔊 Signal Logging
# ----------------------------
var print_signals := false  # Toggle manually to enable/disable logging

# Custom signal emitter with optional logging
# Usage: SignalBus.emit_logged("signal_name", arg)
func emit_logged(name: String, arg: Variant = null) -> void:
	if print_signals:
		var arg_str := ""
		if arg == null:
			arg_str = ""
		elif typeof(arg) == TYPE_ARRAY:
			arg_str = str(arg)
		else:
			arg_str = str(arg)
		print("[Signal] " + name + "(" + arg_str + ")")

	# Emit signal based on argument type
	match typeof(arg):
		TYPE_NIL:
			emit_signal(name)
		TYPE_ARRAY:
			match arg.size():
				0:
					emit_signal(name)
				1:
					emit_signal(name, arg[0])
				2:
					emit_signal(name, arg[0], arg[1])
				3:
					emit_signal(name, arg[0], arg[1], arg[2])
				_:
					print("SignalBus.emit_logged: Too many arguments in array")
					push_error("SignalBus.emit_logged: Too many arguments in array")
		#if arg is not null or an array
		_:
			emit_signal(name, arg)
