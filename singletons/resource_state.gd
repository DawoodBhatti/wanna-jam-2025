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
	SignalBus.connect("resource_count_requested", Callable(self, "_on_resource_count_requested"))
	SignalBus.connect("resource_change_requested", Callable(self, "_on_resource_change_requested"))

# ----------------------------
# 🛠 Public API
# ----------------------------
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
func _on_resource_count_requested() -> void:
	SignalBus.emit_logged("resource_count_finished")

func _on_resource_change_requested(res_type: String, amount: int) -> void:
	match res_type:
		"stone": stone_count += amount
		"wood":  wood_count  += amount
		"food":  food_count  += amount
		"pop":   pop_count   += amount
		_:
			push_warning("[ResourceState] Unknown resource type: %s" % res_type)
			return

	var sig_name := "%s_changed" % res_type
	SignalBus.emit_logged(sig_name, [amount])
