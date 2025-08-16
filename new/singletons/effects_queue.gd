extends Node

var _queue: Array[Dictionary] = []

func queue_effect(effect_callable: Callable, context: Dictionary) -> void:
	_queue.append({
		"callable": effect_callable,
		"context": context
	})

func has_jobs() -> bool:
	return not _queue.is_empty()

func pop_next() -> Dictionary:
	return _queue.pop_front() if has_jobs() else {}

func clear() -> void:
	_queue.clear()
