extends Node2D
class_name EffectsRunner

func run_instant(effect: Dictionary) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Instant effect missing 'type': %s" % str(effect))
		return

	var effect_type := String(effect["type"])
	match effect_type:
		"gain_resource", "resource":
			_handle_gain_resource(effect)
		"medusa":
			print("[EffectsRunner] apply medusa effects")
		"draw_cards":
			_handle_draw_cards(effect)
		"discard_random":
			_handle_discard_random(effect)
		"custom_signal":
			_handle_custom_signal(effect)
		_:
			push_warning("[EffectsRunner] Unknown instant effect type: %s" % effect_type)

func run_queued(effect: Dictionary, ctx: Dictionary = {}) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Queued effect missing 'type': %s" % str(effect))
		(get_parent() as EffectsManager).notify_effect_done(ctx)
		return

	var effect_type := String(effect["type"])
	match effect_type:
		"gain_resource", "resource":
			_handle_gain_resource(effect)
		"medusa":
			print("[EffectsRunner] apply medusa effects")
		"draw_cards":
			_handle_draw_cards(effect)
		"discard_random":
			_handle_discard_random(effect)
		"custom_signal":
			_handle_custom_signal(effect)
		_:
			push_warning("[EffectsRunner] Unknown queued effect type: %s" % effect_type)

	(get_parent() as EffectsManager).notify_effect_done(ctx)

# ----------------------------
# 🧠 Effect Handlers
# ----------------------------
func _handle_gain_resource(effect: Dictionary) -> void:
	if not effect.has("target") or not effect.has("amount"):
		push_error("[EffectsRunner] gain_resource effect missing 'target' or 'amount': %s" % str(effect))
		return

	var target: String = effect["target"]
	var amount: int = int(effect["amount"])

	SignalBus.emit_logged("resource_change_requested", [target, amount])

func _handle_draw_cards(effect: Dictionary) -> void:
	print("[EffectsRunner] Drawing cards:", effect)

func _handle_discard_random(effect: Dictionary) -> void:
	print("[EffectsRunner] Discarding random card:", effect)

func _handle_custom_signal(effect: Dictionary) -> void:
	print("[EffectsRunner] Emitting custom signal:", effect)
