#effects_queue.gd

# autoload which holds the effects we wish to run 
# effects can be instant or queued

# currently the tile manager and the effects manager are 
# the only two entry points into this queue

extends Node

var _queue: Array[Dictionary] = []

func queue_effect(effect_callable: Callable, context: Dictionary) -> void:
	_queue.append({
		"callable": effect_callable,
		"context": context
	})
	
	print("appending callable: ", effect_callable)
	print("context: ", context)

func has_jobs() -> bool:
	return not _queue.is_empty()

func pop_next() -> Dictionary:
	return _queue.pop_front() if has_jobs() else {}

func clear() -> void:
	_queue.clear()
