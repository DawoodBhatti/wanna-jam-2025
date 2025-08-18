extends Node

class_name EffectsManager

@onready var effects_runner: EffectsRunner = $EffectsRunner

func _ready() -> void:
	SignalBus.connect("end_turn_effects_started", Callable(self, "run_end_turn_effects"))
	print("[EffectsManager] ready!")

# Entry point for all effect routing
func handle_effect(effect: Dictionary, ctx: Dictionary) -> void:
	if not effect.has("type"):
		push_error("[EffectsManager] effect missing 'type': %s" % str(effect))
		return

	var is_instant: bool = bool(effect.get("instant", false))

	if is_instant:
		effects_runner.run_instant(effect)
	else:
		var queued_cb: Callable = func(inner_ctx: Dictionary) -> void:
			effects_runner.run_queued(inner_ctx["effect"] as Dictionary, inner_ctx)

		var job_ctx: Dictionary = {
			"effect": effect,
			"card": ctx.get("card", null),
			"timing": String(ctx.get("timing", ""))
		}

		EffectsQueue.queue_effect(queued_cb, job_ctx)

# Begin draining queued end‑turn effects
func run_end_turn_effects() -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged("end_turn_effects_finished")
		return
	_process_next()

# Internal: pop next job and execute; effect must call notify_effect_done() when finished
func _process_next() -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged("end_turn_effects_finished")
		return

	var job: Dictionary = EffectsQueue.pop_next()
	var cb: Callable = job.get("callable", null) as Callable
	var ctx: Dictionary = job.get("context", {}) as Dictionary

	if cb != null and cb.is_valid():
		cb.call(ctx)
	else:
		push_warning("[EffectsManager] Invalid job skipped")
		_process_next()

# Called by EffectsRunner when an effect finishes
func notify_effect_done(ctx: Dictionary) -> void:
	_process_next()
