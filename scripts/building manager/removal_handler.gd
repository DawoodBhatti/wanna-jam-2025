extends Node
class_name RemovalHandler

var mode: String = ""
var _remove_fn: Callable
var _refund_cost_fn: Callable
var _refund_on_recycle: bool

func enter_mode(
	amount: int,
	remove_fn: Callable,
	refund_cost_fn: Callable,
	refund_on_recycle: bool
) -> void:
	mode = "removal"
	_remove_fn = remove_fn
	_refund_cost_fn = refund_cost_fn
	_refund_on_recycle = refund_on_recycle

func process_tile(building_info: Dictionary) -> void:
	var pos: Vector2i = building_info.get("pos", Vector2i.ZERO)
	var spec = building_info.get("spec", null)
	var layer: String = building_info.get("layer", "")
	var source: String = building_info.get("source", "")
	if spec == null:
		return

	if _remove_fn.is_valid():
		_remove_fn.call(pos)

	if _refund_on_recycle and _refund_cost_fn.is_valid():
		_refund_cost_fn.call(spec)

	# Emit RESULT (not intent), with minimal payload
	SignalBus.emit_logged("building_erased", {
		"pos": pos,
		"layer": layer,
		"source": source
	})
