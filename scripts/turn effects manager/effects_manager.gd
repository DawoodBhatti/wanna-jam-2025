extends Node

@onready var effects_runner: Node2D = $EffectsRunner

func _ready() -> void:
	
	#TODO! this might need fixing
	# Discoverable for DeckManager.resolve
	
	# Chain-advance the turn queue when a queued effect finishes
	SignalBus.connect("effect_done", Callable(self, "_process_next"))
	SignalBus.connect("end_turn_effects_started", Callable(self, "run_end_turn_effects"))

	print("[EffectsManager] ready!")


# Single entry point. The ONLY routing rule:
# - If effect.instant == true → run immediately
# - Else → enqueue for turn-ordered resolution
# ctx (e.g., {"card": card, "timing": "play"|"end"}) is passed through untouched for consumers.
func handle_effect(effect: Dictionary, ctx: Dictionary) -> void:
	if not effect.has("type"):
		push_error("[EffectsManager] effect missing 'type': %s" % str(effect))
		return

	var is_instant: bool = bool(effect.get("instant", false))

	if is_instant:
		# Immediate execution path — no queue involvement
		effects_runner.run_instant(effect)
	else:
		# Deferred, sequenced execution path
		EffectsQueue.queue_effect(
			func(inner_ctx: Dictionary) -> void:
				effects_runner.run_queued(inner_ctx.effect, inner_ctx),
			{
				"effect": effect,
				"card": ctx.get("card", null),
				"timing": String(ctx.get("timing", ""))  # kept for analytics/FX, not for routing
			}
		)

# Begin draining the queued turn effects. Emits finished immediately if nothing is queued.
func run_end_turn_effects() -> void:
	SignalBus.emit_logged("end_turn_effects_started")
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged("end_turn_effects_finished")
		return
	_process_next()

# Internal: pop next job and execute. effect_done will call this again.
func _process_next() -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged("end_turn_effects_finished")
		return

	var job: Dictionary = EffectsQueue.pop_next()

	if job.has("callable") and (job["callable"] as Callable).is_valid():
		var cb: Callable = job["callable"]
		var ctx: Dictionary = (job.get("context", {}) as Dictionary)
		cb.call(ctx)
	else:
		push_warning("[EffectsManager] Invalid job skipped")
		_process_next()
