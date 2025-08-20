extends Node
class_name PaintingHandler

var mode: String = ""
var paint_data: Dictionary = {}
var paint_count: int = 0

# Stored callables and flags
var _register_fn: Callable
var _apply_cost_fn: Callable
var _place_cost_on_success: bool
var _remove_fn: Callable
var _refund_cost_fn: Callable
var _refund_on_recycle: bool

func start(mode_name: String, data: Dictionary, count: int,
	register_fn: Callable, apply_cost_fn: Callable, place_cost_on_success: bool,
	remove_fn: Callable, refund_cost_fn: Callable, refund_on_recycle: bool) -> void:
	mode = mode_name
	paint_data = data
	paint_count = count

	_register_fn = register_fn
	_apply_cost_fn = apply_cost_fn
	_place_cost_on_success = place_cost_on_success
	_remove_fn = remove_fn
	_refund_cost_fn = refund_cost_fn
	_refund_on_recycle = refund_on_recycle

func process_tile(building_info: Dictionary) -> void:
	match mode:
		"colour":
			_apply_colour(building_info)
		"texture":
			_apply_texture(building_info)
		"removal":
			_apply_removal(building_info)
		_:
			pass

	if paint_count > 0:
		paint_count -= 1
		if paint_count <= 0:
			clear_mode()

# --- Internal helpers ---

func _apply_colour(building_info: Dictionary) -> void:
	SignalBus.emit_logged("building_placed", building_info)

func _apply_texture(building_info: Dictionary) -> void:
	SignalBus.emit_logged("building_placed", building_info)

func _apply_removal(building_info: Dictionary) -> void:
	if _remove_fn.is_valid():
		_remove_fn.call(building_info.get("pos", Vector2i.ZERO))
	if _refund_on_recycle and _refund_cost_fn.is_valid():
		var spec: StructureSpecs = building_info.get("spec", null)
		if spec != null:
			_refund_cost_fn.call(spec)
	SignalBus.emit_logged("building_removed", building_info)

func clear_mode() -> void:
	mode = ""
	paint_data.clear()
	paint_count = 0
