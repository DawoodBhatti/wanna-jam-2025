extends Node
# 📦 EffectsQueue: Autoload that stores and manages queued effects.
# Effects can be instant or queued; currently only TileManager and EffectsManager enqueue effects.

var _queue: Array[Dictionary] = []
var _queue_counter: int = 0

# ================================
# ➕ Queue Management
# ================================

## Adds an effect to the queue with a unique queue_id.
func queue_effect(effect_callable: Callable, context: Dictionary) -> void:
	var queue_id := _queue_counter
	_queue_counter += 1

	context["queue_id"] = queue_id

	_queue.append({
		"callable": effect_callable,
		"context": context
	})

## Returns true if there are any jobs in the queue.
func has_jobs() -> bool:
	return not _queue.is_empty()

## Removes and returns the next job in the queue, or an empty dictionary if none exist.
func pop_next() -> Dictionary:
	return _queue.pop_front() if has_jobs() else {}

## Clears all jobs from the queue.
func clear() -> void:
	_queue.clear()

# ================================
# 🔍 Queue Inspection
# ================================

## Checks if there are any resolution-blocking effects in the queue.
## Blocking effects are typically placement or removal types.
#TODO currently unused but might be useful at some point
func has_resolution_blocking_effects() -> bool:
	for job in _queue:
		var ctx : Dictionary = job.get("context", {})
		var effect : Dictionary = ctx.get("effect", {})
		var effect_type := String(effect.get("type", ""))
		if effect_type == "placement" or effect_type == "removal":
			return true
	return false

## Returns a list of active queue_ids currently in the queue.
func get_active_queue_ids() -> Array:
	var ids := []
	for job in _queue:
		var ctx : Dictionary = job.get("context", {})
		var id : int = ctx.get("queue_id", -1)
		if id != -1:
			ids.append(id)
	return ids
