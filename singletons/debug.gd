# res://debug/DebugInput.gd
extends Node
# Centralized hotkeys for dev/debug. Safe-guards and null checks throughout.

@export var enabled: bool = true  # flip off to silence all debug input

func _ready() -> void:
	print("[DebugInput] Ready (enabled=%s)" % str(enabled))

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if not event.is_pressed():
		return
	#
	## --- Hand & phase controls ---
	#if Input.is_action_just_pressed("draw_hand"):
		#GameState.draw_cards(5)
		#print("[Debug] draw_hand -> drew 5")
		#return
#
	#if Input.is_action_just_pressed("resolve_hand"):
		#GameState.resolve_hand()
		#print("[Debug] resolve_hand -> resolving")
		#return

	if Input.is_action_just_pressed("advance_phase"):
		GameState.debug_step()
		return

	#if Input.is_action_just_pressed("play_first_card"):
		#var valid_hand := false
		#if GameState.hand is Array:
			#if GameState.hand.size() > 0:
				#valid_hand = true
		#if valid_hand:
			#var card_data = GameState.hand[0]
			#if GameState.has_method("request_play_card"):
				#GameState.request_play_card(card_data)
				#print("[Debug] play_first_card -> requested index 0")
		#else:
			#print("[Debug] play_first_card -> no cards in hand")
	#return
#
	#if Input.is_action_just_pressed("discard_hand"):
		#if GameState.has_method("discard_hand"):
			#GameState.discard_hand()
			#print("[Debug] discard_hand -> discarded")
		#else:
			#print("[Debug] discard_hand -> method missing on GameState")
		#return

	## --- Introspection / logging ---
	#if Input.is_action_just_pressed("print_card_piles"):
		#if GameState:
			#var deck_size := -1
			#var hand_size := -1
			#var discard_size := -1
#
			#if ("deck" in GameState) and (GameState.deck is Array):
				#deck_size = GameState.deck.size()
#
			#if ("hand" in GameState) and (GameState.hand is Array):
				#hand_size = GameState.hand.size()
#
			#if ("discard_pile" in GameState) and (GameState.discard_pile is Array):
				#discard_size = GameState.discard_pile.size()
#
			#print("[Piles] deck=%s hand=%s discard=%s" % [deck_size, hand_size, discard_size])
		#return

	# --- Quick resource poke ---
	if Input.is_action_just_pressed("test_resource_change"):
		if ResourceState:
			if ResourceState.has_method("add_resource"):
				ResourceState.add_resource("stone", 1)
			if ResourceState.has_method("add_resource"):
				ResourceState.add_resource("wood", 1)
			if ResourceState.has_method("add_resource"):
				ResourceState.add_resource("food", 1)
			if ResourceState.has_method("add_resource"):
				ResourceState.add_resource("pop", 1)
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
		
	#if Input.is_action_just_pressed("list_basegrid_tiles"):
		#var base_grid := get_node_or_null("/root/main/Tiles")
		#if base_grid:
			#print_all_tile_layers(base_grid)
		#else:
			#print("[Debug] list_basegrid_tiles -> BaseGrid not found")
		#return


func print_all_tile_layers(base_grid: Node) -> void:
	print("\n=== BASEGRID TILE LAYERS ===")

	var filter_layers := ["StructuresLayer"]  # ← Change this to filter by layer names
	# Leave empty to inspect all layers:
	# var filter_layers := []

	if filter_layers.is_empty():
		print("Inspecting: all layers")
	else:
		print("Inspecting: ", filter_layers)

	for layer_node in base_grid.get_children():
		if not layer_node is TileMapLayer:
			continue

		var layer: TileMapLayer = layer_node
		var layer_name := layer.name

		if not filter_layers.is_empty() and not filter_layers.has(layer_name):
			continue  # Skip layers not in the filter

		var used_cells := layer.get_used_cells()
		var tile_count := used_cells.size()

		print("\n[Layer] %s — %s tile(s)" % [layer_name, tile_count])

		if tile_count == 0:
			print("  (No tiles placed)")
			continue

		for cell_pos in used_cells:
			var source_id := layer.get_cell_source_id(cell_pos)
			var atlas_coords := layer.get_cell_atlas_coords(cell_pos)

			print("  • Pos: %s | Source ID: %s | Atlas: %s" %
				[cell_pos, source_id, atlas_coords])
