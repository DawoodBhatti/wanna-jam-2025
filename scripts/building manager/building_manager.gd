# BuildingManager.gd
# ------------------
# Central controller for all building-related actions:
# - Tracks the active building type and placement mode
# - Handles ghost previews on hover
# - Places and erases tiles on the Level's TileMaps
# - Will later handle multi-paint, procedural placement, and card-driven transformations
#
# Level stays passive — this script queries Level for coordinates and layers.

extends Node

@onready var build_catalogue = BuildCatalogue
@onready var level = get_node("../Tiles")  # Reference to your Level node

var active_building: String = ""
var placement_mode: bool = false
var source_id: int
var atlas_coords: Vector2i
var debug_switch := true

func _ready():
	set_process_input(true)

func start_placement_mode(building_name: String):
	var def := build_catalogue.get_tile("StructuresLayer", building_name)
	if def.is_empty():
		push_error("[BuildingManager] No definition for: %s" % building_name)
		return
	active_building = building_name
	source_id = def.get("source_id", -1)
	var tiles: Dictionary = def.get("tiles", {})
	if tiles.is_empty():
		push_error("[BuildingManager] No tiles for: %s" % building_name)
		return
	atlas_coords = tiles.values()[0]
	placement_mode = true
	if debug_switch:
		print("[BuildingManager] Placement mode started for", building_name)

func stop_placement_mode():
	placement_mode = false
	active_building = ""
	level.ghost_layer.clear()
	if debug_switch:
		print("[BuildingManager] Placement mode stopped.")

func _input(event):
	if not placement_mode:
		return

	if event is InputEventMouseMotion:
		_update_ghost()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_place_tile()
		stop_placement_mode()  # single click ends mode

	elif event.is_action_pressed("cancel"):
		stop_placement_mode()

func _update_ghost():
	var cell_pos = level.get_cell_under_mouse(level.structures_layer)
	level.ghost_layer.clear()
	level.ghost_layer.set_cell(cell_pos, source_id, atlas_coords)
	if debug_switch:
		print("[BuildingManager] Previewing", active_building, "at", cell_pos)

func _place_tile():
	var cell_pos = level.get_cell_under_mouse(level.structures_layer)
	level.structures_layer.set_cell(cell_pos, source_id, atlas_coords)
	if debug_switch:
		print("[BuildingManager] Placed", active_building, "at", cell_pos)
