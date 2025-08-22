# res://debug/DebugInput.gd
extends Node
# Centralized hotkeys for dev/debug. Safe-guards and null checks throughout.

@export var enabled: bool = true  # flip off to silence all debug input

func _ready() -> void:
	var bm : Node2D = get_tree().get_root().get_node("Main/BuildingManager")
	print("[DebugInput] Ready (enabled=%s)" % str(enabled))

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if not event.is_pressed():
		return
		
	if Input.is_action_just_pressed("test_build_mode"):
		print("[DebugInput] Starting placement mode")
		var bm := get_tree().get_root().get_node("Main/BuildingManager")
		if bm:
			#bm.start_placement_mode("StoneTile")  # or "Medusa"
			bm.paint("StoneTile", 50)  # or bm.start_placement_mode("StoneTile")
	
				
	if Input.is_action_just_pressed("advance_phase"):
		GameState.debug_step()
		return
	
	
	# --- Quick resource poke ---
	if Input.is_action_just_pressed("test_resource_change"):
		if ResourceState:
			var types := ["stone", "wood", "food", "pop"]
			for res_type in types:
				SignalBus.emit_logged("resource_change_requested", [res_type, 1])
			print("[Debug] test_resource_change -> +1 to all resources")
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
		
