extends Node

# ----------------------------
# 🪵 Resource Signals
# ----------------------------
signal resource_delta(resource: String, delta: int)
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
signal end_turn_effects_started
signal effect_done
signal end_turn_effects_finished
signal resource_count_started

signal instant_effect_resolved(effect: Dictionary)

# ----------------------------
# 🃏 Card & Hand Signals
# ----------------------------
signal hand_drawn(cards: Array)
signal hand_resolved
signal card_played(card_data: Dictionary)
signal card_clicked(card_data: Dictionary)
signal piles_changed(deck_size: int, hand_size: int, discard_size: int)

signal cards_drawn(cards: Array)
signal card_discarded(card_data: Dictionary)

# ----------------------------
# 🔊 Signal Logging
# ----------------------------
var print_signals: bool = false

func emit_logged(name: String, arg: Variant = null) -> void:
	if print_signals:
		var arg_str: String = ""
		if arg == null:
			arg_str = ""
		elif arg is Array:
			arg_str = str(arg)
		else:
			arg_str = str(arg)
		print("[Signal] %s(%s)" % [name, arg_str])

	match typeof(arg):
		TYPE_NIL:
			emit_signal(name)
		TYPE_ARRAY:
			var arr: Array = arg as Array
			match arr.size():
				0: emit_signal(name)
				1: emit_signal(name, arr[0])
				2: emit_signal(name, arr[0], arr[1])
				3: emit_signal(name, arr[0], arr[1], arr[2])
				4: emit_signal(name, arr[0], arr[1], arr[2], arr[3])
				_: push_error("SignalBus.emit_logged: Too many arguments in array")
		_:
			emit_signal(name, arg)
