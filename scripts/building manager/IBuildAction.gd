# IBuildAction.gd
# ----------------
# Interface/contract for all building action modules.
# Any action (PlacementAction, PaintingAction, RemovalAction, etc.)
# must implement these three methods so the BuildingManager can
# swap them in and out without caring which one is active.

extends Node
class_name IBuildAction

# Called when the action is activated.
# `params` is a dictionary so you can pass any needed data
# (e.g. building_name, paint limit, etc.)
func start(params: Dictionary) -> void:
	pass

# Called every frame the action is active, with the current input event.
# This is where the action decides how to respond to mouse/keyboard input.
func process_input(event: InputEvent) -> void:
	pass

# Called when the action is stopped or cancelled.
# Use this to clean up state, clear previews, etc.
func stop() -> void:
	pass
