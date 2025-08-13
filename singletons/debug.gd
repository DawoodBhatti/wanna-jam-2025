# res://debug/DebugInput.gd
extends Node
# Centralized hotkeys for dev/debug. Safe-guards and null checks throughout.

@export var enabled: bool = true  # flip off to silence all debug input

@onready var game_state: Node      = get_node_or_null("/root/Gamestate")
@onready var resources: Node       = get_node_or_null("/root/Resources")
@onready var hud: Node             = get_node_or_null("/root/main/HUD")
@onready var deck_manager: Node    = get_node_or_null("/root/main/DeckManager")

func _ready() -> void:
	print("[DebugInput] Ready (enabled=%s)" % str(enabled))

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if not event.is_pressed():
		return
	
	# --- Hand & phase controls ---
	if Input.is_action_just_pressed("draw_hand"):
		if game_state and game_state.has_method("draw_cards"):
			game_state.draw_cards(5)
			print("[Debug] draw_hand -> drew 5")
		return

	if Input.is_action_just_pressed("resolve_hand"):
		if game_state and game_state.has_method("resolve_hand"):
			game_state.resolve_hand()
			print("[Debug] resolve_hand -> resolving")
		return

	if Input.is_action_just_pressed("advance_phase"):
		if game_state and game_state.has_method("advance_phase"):
			game_state.advance_phase()
			print("[Debug] advance_phase -> advancing")
		return

	if Input.is_action_just_pressed("play_first_card"):
		if game_state and ("hand" in game_state):
			var valid_hand := false
			if game_state.hand is Array:
				if game_state.hand.size() > 0:
					valid_hand = true
			if valid_hand:
				var card_data = game_state.hand[0]
				if game_state.has_method("request_play_card"):
					game_state.request_play_card(card_data)
					print("[Debug] play_first_card -> requested index 0")
			else:
				print("[Debug] play_first_card -> no cards in hand")
		return

	if Input.is_action_just_pressed("discard_hand"):
		if game_state and game_state.has_method("discard_hand"):
			game_state.discard_hand()
			print("[Debug] discard_hand -> discarded")
		else:
			print("[Debug] discard_hand -> method missing on GameState")
		return

	# --- Introspection / logging ---
	if Input.is_action_just_pressed("print_card_piles"):
		if game_state:
			var deck_size := -1
			var hand_size := -1
			var discard_size := -1

			if ("deck" in game_state) and (game_state.deck is Array):
				deck_size = game_state.deck.size()

			if ("hand" in game_state) and (game_state.hand is Array):
				hand_size = game_state.hand.size()

			if ("discard_pile" in game_state) and (game_state.discard_pile is Array):
				discard_size = game_state.discard_pile.size()

			print("[Piles] deck=%s hand=%s discard=%s" % [deck_size, hand_size, discard_size])
		return

	# --- Quick resource poke ---
	if Input.is_action_just_pressed("test_resource_change"):
		if resources:
			if resources.has_method("add_wood"):
				resources.add_wood(1)
			if resources.has_method("add_food"):
				resources.add_food(1)
			if resources.has_method("add_stone"):
				resources.add_stone(1)
			if resources.has_method("add_pop"):
				resources.add_pop(1)
			print("[Debug] test_resource_change -> +1 to all available")
		return

	# --- UI / overlay toggles (adjust paths as needed) ---
	if Input.is_action_just_pressed("toggle_grid"):
		var grid := get_node_or_null("/root/main/Tiles/GridOverlay")
		if grid:
			grid.visible = not grid.visible
			var state := "off"
			if grid.visible:
				state = "on"
			print("[Debug] toggle_grid -> %s" % state)
		return

	if Input.is_action_just_pressed("toggle_instructions"):
		var instructions := get_node_or_null("/root/main/HUD/Instructions")
		if instructions:
			instructions.visible = not instructions.visible
			var state2 := "off"
			if instructions.visible:
				state2 = "on"
			print("[Debug] toggle_instructions -> %s" % state2)
		return
