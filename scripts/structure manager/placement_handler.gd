extends Node
class_name PlacementHandler

var mode: String = ""
var _register_fn: Callable
var _apply_cost_fn: Callable
var _place_cost_on_success: bool

func enter_mode(
	data: Dictionary,
	amount: int,
	register_fn: Callable,
	apply_cost_fn: Callable,
	place_cost_on_success: bool
) -> void:
	mode = "placement"
	_register_fn = register_fn
	_apply_cost_fn = apply_cost_fn
	_place_cost_on_success = place_cost_on_success
	# Mode setup logic can go here

func process_tile(building_info: Dictionary) -> void:
	var pos: Vector2i = building_info.get("pos", Vector2i.ZERO)
	var spec: StructureSpecs = building_info.get("spec", null)
	if spec == null:
		return

	if _register_fn.is_valid():
		_register_fn.call(pos, spec)

	if _place_cost_on_success and _apply_cost_fn.is_valid():
		_apply_cost_fn.call(spec)

	SignalBus.emit_logged("building_placed", building_info)
