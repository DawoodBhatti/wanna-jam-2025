extends Node2D

class_name EffectsRunner

func run_instant(effect: Dictionary) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Instant effect missing 'type': %s" % str(effect))
		return

	match String(effect.get("type", "")):
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
			push_warning("[EffectsRunner] Unknown instant effect type: %s" % String(effect.get("type", "")))

func run_queued(effect: Dictionary, ctx: Dictionary = {}) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Queued effect missing 'type': %s" % str(effect))
		var manager: EffectsManager = get_parent() as EffectsManager
		manager.notify_effect_done(ctx)
		return

	match String(effect.get("type", "")):
		"gain_resource", "resource":
			_handle_gain_resource(effect)
			(get_parent() as EffectsManager).notify_effect_done(ctx)

		"medusa":
			print("[EffectsRunner] apply medusa effects")
			(get_parent() as EffectsManager).notify_effect_done(ctx)

		"draw_cards":
			_handle_draw_cards(effect)
			(get_parent() as EffectsManager).notify_effect_done(ctx)

		"discard_random":
			_handle_discard_random(effect)
			(get_parent() as EffectsManager).notify_effect_done(ctx)

		"custom_signal":
			_handle_custom_signal(effect)
			(get_parent() as EffectsManager).notify_effect_done(ctx)

		_:
			push_warning("[EffectsRunner] Unknown queued effect type: %s" % String(effect.get("type", "")))
			(get_parent() as EffectsManager).notify_effect_done(ctx)

# Placeholder handlers — implement as needed
func _handle_gain_resource(effect: Dictionary) -> void:
	print("[EffectsRunner] Gaining resource:", effect)

func _handle_draw_cards(effect: Dictionary) -> void:
	print("[EffectsRunner] Drawing cards:", effect)

func _handle_discard_random(effect: Dictionary) -> void:
	print("[EffectsRunner] Discarding random card:", effect)

func _handle_custom_signal(effect: Dictionary) -> void:
	print("[EffectsRunner] Emitting custom signal:", effect)
