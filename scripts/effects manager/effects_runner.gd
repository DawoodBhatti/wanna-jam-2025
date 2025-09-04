extends Node
class_name EffectsRunner

@onready var bm: Node = get_tree().get_root().get_node("Main/ConstructionManager")
@onready var custom_effects: Node = $CustomEffects

var debug_level: int

# ================================
# 🚀 Lifecycle
# ================================

## Initializes the runner and sets debug level from the signal bus.
func _ready() -> void:
	debug_level = SignalBus.signal_detail

# ================================
# 🎯 Entry Points
# ================================

## Executes an effect immediately without queuing.
func run_instant(ctx: Dictionary) -> void:
	_execute_effect(ctx)

## Executes a queued effect:
## - Runs the effect
## - If blocking, stores it in the manager until completion
## - If non-blocking, emits completion immediately
func run_queued(ctx: Dictionary) -> void:
	var effect : Dictionary = ctx.get("effect", {})

	if effect.get("instant", false):
		push_warning("[EffectsRunner] Queued effect marked as INSTANT — this should not happen!")

	_execute_effect(ctx)

	if _is_blocking(effect):
		(get_parent() as EffectsManager)._current_blocking_effect = ctx
		return

	var queue_id : int = ctx.get("queue_id", -1)
	if queue_id != -1:
		SignalBus.emit_logged("queued_effect_completed", queue_id)

# ================================
# 🧠 Dispatcher
# ================================

## Routes an effect to the correct handler based on its type.
func _execute_effect(ctx: Dictionary) -> void:
	var effect : Dictionary = ctx.get("effect", {})

	if not effect.has("type"):
		push_error("[EffectsRunner] Effect missing 'type': %s" % str(effect))
		return

	match String(effect["type"]):
		"resource_change": _handle_resource_change(effect)
		"draw_cards": _handle_draw_cards(effect)
		"placement": _handle_placement(effect)
		"removal": _handle_removal(effect)
		_: custom_effects.handle_custom_effect(ctx)

# ================================
# 🛠 Effect Handlers
# ================================

## Handles a resource change effect.
func _handle_resource_change(effect: Dictionary) -> void:
	var target : String = effect.get("target", "")
	var amount := int(effect.get("amount", 0))
	if target == "":
		push_error("[EffectsRunner] Missing target in resource_change")
		return
	SignalBus.emit_logged("resource_change_requested", [target, amount])

## Handles a draw cards effect.
func _handle_draw_cards(effect: Dictionary) -> void:
	var amount := int(effect.get("amount", 1))
	SignalBus.emit_logged("draw_cards_requested", amount)

## Handles a placement effect (blocking).
func _handle_placement(effect: Dictionary) -> void:
	var tile : String = effect.get("tile_name", "")
	var amount := int(effect.get("amount", 1))
	if tile == "":
		push_error("[EffectsRunner] Missing tile_name in placement")
		return
	bm.placement(tile, amount)

## Handles a removal effect (blocking).
func _handle_removal(effect: Dictionary) -> void:
	var tile : String = effect.get("tile_name", "")
	var amount := int(effect.get("amount", 1))
	if tile == "":
		push_error("[EffectsRunner] Missing tile_name in removal")
		return
	bm.removal(tile, amount)

# ================================
# 🚦 Blocking Effect Detection
# ================================

## Determines if an effect is blocking:
## - Explicitly marked as blocking
## - Or inherently blocking types (placement/removal)
func _is_blocking(effect: Dictionary) -> bool:
	return effect.get("blocking", false) or effect.get("type", "") in ["placement", "removal"]
