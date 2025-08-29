extends Node
class_name EffectsManager

@onready var effects_runner: EffectsRunner = $EffectsRunner

func _ready() -> void:
	# Only one hook now — all delayed effects drain here
	SignalBus.connect("end_turn_effects_started", Callable(self, "run_queue"))

# --- Effect Routing ---
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
			"card": ctx.get("card", null)
		}

		EffectsQueue.queue_effect(queued_cb, job_ctx)

# --- Explicit helpers ---
func run_instant_effects(card_id: String) -> void:
	var card := CardCatalogue.get_card_by_id(card_id)
	if card.is_empty():
		push_warning("[EffectsManager] Unknown card ID: %s" % card_id)
		return
	for effect: Dictionary in card.get("instant_effects", []):
		var e: Dictionary = effect.duplicate(true)
		e["instant"] = true
		handle_effect(e, { "card": card })

func queue_end_turn_effects(card_id: String) -> void:
	var card := CardCatalogue.get_card_by_id(card_id)
	if card.is_empty():
		return
	for effect in card.get("end_turn_effects", []):
		EffectsQueue.queue_effect(
			func(inner_ctx): effects_runner.run_queued(inner_ctx["effect"], inner_ctx),
			{ "effect": effect, "card": card }
		)

func queue_remain_effects(card_id: String) -> void:
	var card := CardCatalogue.get_card_by_id(card_id)
	if card.is_empty():
		return
	for effect in card.get("remain_effects", []):
		EffectsQueue.queue_effect(
			func(inner_ctx): effects_runner.run_queued(inner_ctx["effect"], inner_ctx),
			{ "effect": effect, "card": card }
		)

# --- Unified drain ---
func run_queue(finished_signal: String = "end_turn_effects_finished") -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged(finished_signal)
		return
	_process_next()

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

func notify_effect_done(ctx: Dictionary) -> void:
	_process_next()
