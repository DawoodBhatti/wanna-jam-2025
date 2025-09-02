extends Node
class_name EffectsRunner

@onready var bm: Node = get_tree().get_root().get_node("Main/ConstructionManager")
@onready var custom_effects: Node = $CustomEffects

var debug_level: int

func _ready() -> void:
	debug_level = SignalBus.signal_detail

# =========================================================
# 🔄 Shared Effect Execution
# =========================================================
func _execute_effect(ctx: Dictionary) -> void:
	var effect: Dictionary = ctx.get("effect", {})
	if debug_level >= 1:
		print("[EffectsRunner] Triggering effect:", effect)

	if not effect.has("type"):
		push_error("[EffectsRunner] Effect missing 'type': %s" % str(effect))
		return

	match String(effect["type"]):
		"resource_change":
			_handle_resource_change(effect)
		"draw_cards":
			_handle_draw_cards(effect)
		"placement":
			_handle_placement(effect)
		"removal":
			_handle_removal(effect)
		_:
			custom_effects.handle_custom_effect(ctx) # pass full ctx for tile effects

# =========================================================
# ⚡ Instant Effects
# =========================================================
func run_instant(ctx: Dictionary) -> void:
	_execute_effect(ctx)

# =========================================================
# ⏳ Queued Effects
# =========================================================
func run_queued(ctx: Dictionary) -> void:
	_execute_effect(ctx)
	(get_parent() as EffectsManager).notify_effect_done()

# =========================================================
# 🧠 Effect Handlers
# =========================================================
func _handle_resource_change(effect: Dictionary) -> void:
	if not effect.has("target") or not effect.has("amount"):
		push_error("[EffectsRunner] resource_change effect missing 'target' or 'amount': %s" % str(effect))
		return
	var target: String = effect["target"]
	var amount: int = int(effect["amount"])
	SignalBus.emit_logged("resource_change_requested", [target, amount])

func _handle_draw_cards(effect: Dictionary) -> void:
	var amount: int = int(effect.get("amount", 1))
	SignalBus.emit_logged("draw_cards_requested", amount)
	if debug_level >= 1:
		print("[EffectsRunner] Drawing cards:", amount)

func _handle_placement(effect: Dictionary) -> void:
	if not effect.has("tile_name") or not effect.has("amount"):
		push_error("[EffectsRunner] placement effect missing 'tile_name' or 'amount': %s" % str(effect))
		return
	bm.placement(effect["tile_name"], effect["amount"])

func _handle_removal(effect: Dictionary) -> void:
	if not effect.has("tile_name") or not effect.has("amount"):
		push_error("[EffectsRunner] removal effect missing 'tile_name' or 'amount': %s" % str(effect))
		return
	bm.removal(effect["tile_name"], effect["amount"])
