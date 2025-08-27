extends Node2D
class_name EffectsRunner


@onready var bm : Node2D = get_tree().get_root().get_node("Main/BuildingManager")

func run_instant(effect: Dictionary) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Instant effect missing 'type': %s" % str(effect))
		return

	var effect_type := String(effect["type"])
	match effect_type:
		"resource_change":
			_handle_resource_change(effect)
		"draw_cards":
			_handle_draw_cards(effect)
		"placement":
			_handle_placement(effect)
		"removal":
			_handle_removal(effect)
		_:
			push_warning("[EffectsRunner] Unknown instant effect type: %s" % effect_type)
			

func run_queued(effect: Dictionary, ctx: Dictionary = {}) -> void:
	if not effect.has("type"):
		push_error("[EffectsRunner] Queued effect missing 'type': %s" % str(effect))
		(get_parent() as EffectsManager).notify_effect_done(ctx)
		return

	var effect_type := String(effect["type"])
	match effect_type:
		"resource_change":
			_handle_resource_change(effect)
		"draw_cards":
			_handle_draw_cards(effect)
		"placement":
			_handle_placement(effect)
		"removal":
			_handle_removal(effect)
		_:
			push_warning("[EffectsRunner] Unknown instant effect type: %s" % effect_type)
			
	(get_parent() as EffectsManager).notify_effect_done(ctx)

# ----------------------------
# 🧠 Effect Handlers
# ----------------------------
func _handle_resource_change(effect: Dictionary) -> void:
	if not effect.has("target") or not effect.has("amount"):
		push_error("[EffectsRunner] gain_resource effect missing 'target' or 'amount': %s" % str(effect))
		return

	var target: String = effect["target"]
	var amount: int = int(effect["amount"])

	SignalBus.emit_logged("resource_change_requested", [target, amount])

func _handle_draw_cards(effect: Dictionary) -> void:
	SignalBus.emit_logged("draw_cards_requested", 1)
	print("[EffectsRunner] Drawing cards:", effect)

func _handle_placement(effect: Dictionary) -> void:
	bm.placement(effect["tile_name"], effect["amount"])  

func _handle_removal(effect: Dictionary) -> void:
	bm.removal(effect["tile_name"], effect["amount"])  
	
