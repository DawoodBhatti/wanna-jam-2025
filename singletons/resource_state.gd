extends Node

# ----------------------------
# 📊 Resource Storage
# ----------------------------
var stone_count: int = 0
var wood_count: int  = 0
var food_count: int  = 0
var pop_count: int   = 0

# ----------------------------
# 🚀 Lifecycle
# ----------------------------
func _ready() -> void:
	if SignalBus:
		# Listen for request to count resources at end-of-turn
		SignalBus.connect("resource_count_requested", Callable(self, "_on_resource_count_requested"))
	else:
		push_warning("[ResourceState] No SignalBus found")

# ----------------------------
# 🛠 Public API
# ----------------------------
func add_resource(res_type: String, amount: int) -> void:
	match res_type:
		"stone": stone_count += amount
		"wood":  wood_count  += amount
		"food":  food_count  += amount
		"pop":   pop_count   += amount
		_:
			push_warning("[ResourceState] Unknown resource type: %s" % res_type)
			return
	
	_emit_resource_signal(res_type, amount)

func set_resource(res_type: String, value: int) -> void:
	var delta: int
	match res_type:
		"stone": delta = value - stone_count; stone_count = value
		"wood":  delta = value - wood_count;  wood_count  = value
		"food":  delta = value - food_count;  food_count  = value
		"pop":   delta = value - pop_count;   pop_count   = value
		_:
			push_warning("[ResourceState] Unknown resource type: %s" % res_type)
			return

	_emit_resource_signal(res_type, delta)

func get_resource(res_type: String) -> int:
	match res_type:
		"stone": return stone_count
		"wood":  return wood_count
		"food":  return food_count
		"pop":   return pop_count
		_:       return 0

# ----------------------------
# 📡 Signal Handling
# ----------------------------
func _emit_resource_signal(res_type: String, amount: int) -> void:
	var sig_name := "%s_changed" % res_type
	SignalBus.emit_logged(sig_name, [amount])

func _on_resource_count_requested() -> void:
	# Step 1: Emit outcome that counting has started/completed for any listeners
	SignalBus.emit_logged("resource_count_finished")

	# Step 2: Push current values
	SignalBus.emit_logged("stone_changed", [stone_count])
	SignalBus.emit_logged("wood_changed", [wood_count])
	SignalBus.emit_logged("food_changed", [food_count])
	SignalBus.emit_logged("pop_changed", [pop_count])
