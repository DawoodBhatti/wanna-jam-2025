extends Node
class_name EffectsManager

# 🧠 EffectsManager: Routes card effects to the appropriate runner.
# Handles both instant and queued effects, and manages end-turn effect flow.

@onready var effects_runner: EffectsRunner = $EffectsRunner

# -------------------------------------------------------------------
# 🚦 Initialization & Signal Wiring
# -------------------------------------------------------------------
func _ready() -> void:
	SignalBus.connect("end_turn_effects_started", Callable(self, "run_end_turn_effects"))
	print("[EffectsManager] ready!")

# -------------------------------------------------------------------
# 🎯 Effect Routing Entry Point
# -------------------------------------------------------------------
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

# -------------------------------------------------------------------
# ⏳ End-Turn Effect Drain
# -------------------------------------------------------------------
func run_end_turn_effects() -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged("end_turn_effects_finished")
		return
	_process_next()

# -------------------------------------------------------------------
# 🔄 Queued Effect Execution
# -------------------------------------------------------------------
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

# -------------------------------------------------------------------
# ✅ Effect Completion Callback
# -------------------------------------------------------------------
func notify_effect_done(ctx: Dictionary) -> void:
	_process_next()

# -------------------------------------------------------------------
# ✨ Card Effect Delegation
# -------------------------------------------------------------------
# Used by DeckManager to run a card's effects instantly
func run_card_effects(card_id: String, timing: String = "play") -> void:
	var card: Dictionary = CardCatalogue.get_card_by_id(card_id)
	if card.is_empty():
		push_warning("[EffectsManager] Unknown card ID: %s" % card_id)
		return

	var effects: Array = card.get("effects_on_" + timing, [])
	for effect: Dictionary in effects:
		var e: Dictionary = effect.duplicate(true)
		e["instant"] = true
		handle_effect(e, {
			"card": card,
			"timing": timing
		})
