extends Node

# SignalBus.gd
# ------------
# Global event hub for decoupling systems.
# Defines and emits signals for all game events that require action
# Allows other systems to communicate without direct references.

# ----------------------------
# 🔊 Signal Logging
# ----------------------------
# 0 = silent, 1 =  names and arguments, 2 = names, arguments and call stack
var signal_detail: int = 1

# ----------------------------
# 🪵 Resource Signals
# ----------------------------
signal resource_change_requested(resource: String, delta: int)

signal stone_changed(amount: int)
signal wood_changed(amount: int)
signal food_changed(amount: int)
signal pop_changed(amount: int)

# ----------------------------
# 🎮 Game Flow Signals
# ----------------------------
signal game_started

signal phase_changed(new_phase: String)
signal play_phase_state_changed(state: String)

signal cancel_active_modes_requested
signal cancel_active_modes                     # outcome

signal turn_ended(turn_number: int)

signal end_turn_effects_started
signal end_turn_effects_finished

signal resource_count_requested                 # outcome only
signal resource_count_finished

signal instant_effect_resolved(card_id: String)  # outcome only

# ----------------------------
# 🃏 Card & Hand Signals
# ----------------------------
signal card_clicked(card_id: String)

signal draw_hand_requested                 # Intent: "I want a full hand" → handled by GameState
signal draw_cards_requested(count: int)    # Outcome: "Draw X cards now" → handled by CardManager
signal hand_drawn(cards: Array)            # Outcome: cards are actually in hand

signal resolve_hand_requested
signal hand_resolved

signal card_play_requested(card_id: String)
signal card_play_denied(card_id: String)
signal card_was_played(card_id: String)

signal piles_changed(deck_size: int, hand_size: int, discard_size: int)  # outcome only

signal cards_drawn(cards: Array)                # outcome alias if needed

# ----------------------------
# 🏗 Building Placement Signals
# ----------------------------
# These are optional decoupling points — BuildingManager can call
# placement/erasure directly without going through SignalBus if desired.

signal place_building_requested(tile_info: Dictionary)   # Player/tool requests a placement
signal building_placed(tile_info: Dictionary)            # Placement committed

signal erase_building_requested(tile_info: Dictionary)   # Player/tool requests removal
signal building_erased(tile_info: Dictionary)            # Removal committed

# Paint / Build Modes (future use)
signal paint_mode_started(mode: String, data: Dictionary, count: int)
signal paint_mode_completed(mode: String, data: Dictionary, count: int)
signal place_mode_completed
signal remove_mode_completed

# ----------------------------
# 📣 Emit wrapper with debug logging
# ----------------------------
func emit_logged(name: String, arg: Variant = null) -> void:
	if signal_detail >= 1:
		var arg_str: String = ""

		# Special-case: only print card names for hand_drawn
		if name == "hand_drawn" and typeof(arg) == TYPE_ARRAY:
			var card_names: Array = []
			for card in arg[0]:
				if typeof(card) == TYPE_DICTIONARY and card.has("name"):
					card_names.append(card["name"])
			arg_str = str(card_names)
		elif arg != null:
			arg_str = str(arg)

		print("[Signal] %s(%s)" % [name, arg_str])

		if signal_detail >= 2:
			print("--- Signal emit call stack ---")
			print_stack()
			print("------------------------------")

	# Actual emit
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
