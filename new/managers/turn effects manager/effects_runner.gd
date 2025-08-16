extends Node
class_name EffectsRunner

func run_instant(effect: Dictionary) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Instant effect missing 'type': %s" % str(effect))
		return
	match String(effect["type"]):
		"gain_resource", "resource":
			_handle_gain_resource(effect)
		"draw_cards":
			_handle_draw_cards(effect)
		"discard_random":
			_handle_discard_random(effect)
		"custom_signal":
			_handle_custom_signal(effect)
		_:
			push_warning("[EffectsRunner] Unknown instant effect type: %s" % String(effect["type"]))
	SignalBus.emit_logged("instant_effect_resolved", effect)

func run_queued(effect: Dictionary, ctx: Dictionary = {}) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Queued effect missing 'type': %s" % str(effect))
		SignalBus.emit_logged("effect_done", effect)
		return

	match String(effect["type"]):
		"resource", "gain_resource":
			_handle_gain_resource(effect)
			SignalBus.emit_logged("effect_done", effect)

		"medusa":
			print("[EffectsRunner] apply medusa effects")
			SignalBus.emit_logged("effect_done", effect)

		"draw_cards":
			_handle_draw_cards(effect)
			SignalBus.emit_logged("effect_done", effect)

		"discard_random":
			_handle_discard_random(effect)
			SignalBus.emit_logged("effect_done", effect)

		"custom_signal":
			_handle_custom_signal(effect)
			SignalBus.emit_logged("effect_done", effect)

		_:
			push_warning("[EffectsRunner] Unknown queued effect type: %s" % String(effect["type"]))
			SignalBus.emit_logged("effect_done", effect)

func _handle_gain_resource(effect: Dictionary) -> void:
	var resource: String = effect.get("resource", String(effect.get("target", "")))
	var amount: int = int(effect.get("amount", 0))
	if resource == "" or amount == 0:
		return

	if "add_resource" in ResourceState:
		ResourceState.add_resource(resource, amount)
	elif "resources" in GameState:
		GameState.resources[resource] = int(GameState.resources.get(resource, 0)) + amount

	SignalBus.emit_logged("resource_delta", [resource, amount])

	match resource:
		"stone":
			SignalBus.emit_logged("stone_changed", amount)
		"wood":
			SignalBus.emit_logged("wood_changed", amount)
		"food":
			SignalBus.emit_logged("food_changed", amount)
		"pop", "population":
			SignalBus.emit_logged("pop_changed", amount)

func _handle_draw_cards(effect: Dictionary) -> void:
	var amount: int = int(effect.get("amount", 1))
	if amount <= 0:
		return
	var drawn: Array = []
	if "draw_from_deck" in DeckState:
		drawn = DeckState.draw_from_deck(amount)
	SignalBus.emit_logged("cards_drawn", drawn)

func _handle_discard_random(effect: Dictionary) -> void:
	var amount: int = int(effect.get("amount", 1))
	if amount <= 0 or not ("hand" in DeckState):
		return
	for _i: int in amount:
		if DeckState.hand.is_empty():
			break
		var random_card: Dictionary = DeckState.hand.pick_random()
		DeckState.move_card_to_discard(random_card)
		SignalBus.emit_logged("card_discarded", random_card)

func _handle_custom_signal(effect: Dictionary) -> void:
	var sig: String = String(effect.get("signal", ""))
	var args: Array = (effect.get("args", []) as Array)
	if sig != "":
		SignalBus.emit_logged(sig, args)
