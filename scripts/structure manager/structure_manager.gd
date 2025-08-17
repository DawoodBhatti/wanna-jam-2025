extends Node

## Unified “building” concept: any placeable from BuildCatalogue (tiles, structures, etc.)

var _instances: Array[Dictionary] = []
var _by_pos: Dictionary = {}

@export var place_cost_on_success: bool = true
@export var refund_on_recycle: bool = true

@onready var placement_handler: PlacementHandler = $Placement
@onready var removal_handler: RemovalHandler = $Removal
@onready var painting_handler: PaintingHandler = $Painting

func _ready() -> void:
	SignalBus.paint_mode_started.connect(_on_start_paint_mode_request)
	SignalBus.building_placed.connect(_on_building_placed)
	SignalBus.building_erased.connect(_on_building_removed)

# === Public API ===

func start_placement(data: Dictionary, amount: int = 0) -> void:
	placement_handler.enter_mode(
		data,
		amount,
		_register_instance,
		_apply_cost,
		place_cost_on_success
	)

func start_removal(amount: int = 0) -> void:
	removal_handler.enter_mode(
		amount,
		_remove_instance_at,
		_refund_cost,
		refund_on_recycle
	)

func start_painting(mode: String, data: Dictionary = {}, count: int = 0) -> void:
	painting_handler.start(mode, data, count, _register_instance, _apply_cost, place_cost_on_success, _remove_instance_at, _refund_cost, refund_on_recycle)

func start_removal_paint(count: int = 0) -> void:
	painting_handler.start("removal", {}, count, _register_instance, _apply_cost, place_cost_on_success, _remove_instance_at, _refund_cost, refund_on_recycle)

# === Bookkeeping ===

func _register_instance(pos: Vector2i, spec: StructureSpecs) -> void:
	var record: Dictionary = {"pos": pos, "spec": spec}
	_instances.append(record)
	_by_pos[pos] = record

func _remove_instance_at(pos: Vector2i) -> void:
	if _by_pos.has(pos):
		var record: Dictionary = _by_pos[pos]
		_instances.erase(record)
		_by_pos.erase(pos)

# === Costs ===

func _apply_cost(spec: StructureSpecs) -> void:
	# TODO: implement cost logic
	pass

func _refund_cost(spec: StructureSpecs) -> void:
	# TODO: implement refund logic
	pass

# === Event Handlers ===

func _on_start_paint_mode_request(mode: String, data: Dictionary, count: int) -> void:
	start_painting(mode, data, count)

func _on_building_placed(building_info: Dictionary) -> void:
	if painting_handler.mode != "":
		painting_handler.process_tile(building_info)
	else:
		placement_handler.process_tile(building_info)

func _on_building_removed(building_info: Dictionary) -> void:
	if painting_handler.mode != "":
		painting_handler.process_tile(building_info)
	else:
		removal_handler.process_tile(building_info)
