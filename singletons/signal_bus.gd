extends Node

# ----------------------------
# 🔊 Signal Logging
# ----------------------------
var print_signals: bool = true

# ----------------------------
# 🪵 Resource Signals
# ----------------------------
signal resource_delta_requested(resource: String, delta: int)
signal resource_delta(resource: String, delta: int)   # outcome

signal stone_change_requested(amount: int)
signal stone_changed(amount: int)

signal wood_change_requested(amount: int)
signal wood_changed(amount: int)

signal food_change_requested(amount: int)
signal food_changed(amount: int)

signal pop_change_requested(amount: int)
signal pop_changed(amount: int)

# ----------------------------
# 🎮 Game Flow Signals
# ----------------------------
signal game_started

signal phase_change_requested(new_phase: String)
signal phase_changed(new_phase: String)

signal play_phase_state_change_requested(state: String)
signal play_phase_state_changed(state: String)

signal cancel_active_modes_requested
signal cancel_active_modes                     # outcome

signal turn_ended(turn_number: int)

signal end_turn_effects_started
signal end_turn_effects_finished

signal resource_count_started                  # outcome only

signal instant_effect_resolved(effect: Dictionary)  # outcome only

# ----------------------------
# 🃏 Card & Hand Signals
# ----------------------------
signal draw_cards_requested(count: int)
signal hand_drawn(cards: Array)

signal resolve_hand_requested
signal hand_resolved

signal play_card_requested(card_data: Dictionary)
signal card_played(card_data: Dictionary)

signal discard_card_requested(card_data: Dictionary)
signal card_discarded(card_data: Dictionary)

signal piles_changed(deck_size: int, hand_size: int, discard_size: int)  # outcome only

signal cards_drawn(cards: Array)                # outcome alias if needed

# ----------------------------
# 🏗 Building Placement Signals
# ----------------------------
signal place_building_requested(tile_info: Dictionary)
signal building_placed(tile_info: Dictionary)

signal erase_building_requested(tile_info: Dictionary)
signal building_erased(tile_info: Dictionary)

signal start_paint_mode_requested(mode: String, data: Dictionary, count: int)
signal paint_mode_started(mode: String, data: Dictionary, count: int)   # optional outcome

signal place_mode_completed
signal remove_mode_completed

# ----------------------------
# 📣 Emit wrapper with debug logging
# ----------------------------
func emit_logged(name: String, arg: Variant = null) -> void:
	if print_signals:
		var arg_str: String = ""

		# Special-case: only print card names for hand_drawn
		if name == "hand_drawn" and typeof(arg) == TYPE_ARRAY:
			var card_names: Array = []
			for card in arg[0]: # arg[0] is the array of card dictionaries
				if typeof(card) == TYPE_DICTIONARY and card.has("name"):
					card_names.append(card["name"])
			arg_str = str(card_names)
		elif arg != null:
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
