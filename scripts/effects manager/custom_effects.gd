extends Node

# Map of effect type strings → handler functions
var custom_effect_map: Dictionary = {}

func _ready() -> void:
	# Register all custom effects here
	custom_effect_map = {
		"square_petrify": square_petrify,
		"set_fired": set_fired
	}

# Entry point for all non-core effects.
# Called from EffectsRunner._execute_effect() when type is not one of the built-ins.
func handle_custom_effect(ctx: Dictionary) -> void:
	var effect: Dictionary = ctx.get("effect", {})
	var effect_type: String = String(effect.get("type", ""))

	match effect_type:
		"square_petrify":
			square_petrify(ctx)
		"set_fired":
			set_fired(ctx)
		_:
			push_warning("[CustomEffects] Unknown custom effect type: %s" % effect_type)


# --- Custom effect implementations ---
func square_petrify(ctx: Dictionary) -> void:
	var effect: Dictionary = ctx["effect"]
	var size: int = int(effect.get("size", 1))
	var meta: Dictionary = ctx.get("meta", {})
	print("[CustomEffects] Medusa petrifies in a square of size %d" % size)
	if not meta.is_empty():
		print("  Layer:", meta.get("layer_name", ""), "Cell:", meta.get("cell", ""))
	set_fired(ctx)


func set_fired(ctx: Dictionary) -> void:
	var tile_key: String = ctx.get("tile_key", "")
	if tile_key != "":
		TileState.set_tile_fired(tile_key)
		print("[CustomEffects] Marked tile as fired:", tile_key)
	else:
		print("[CustomEffects] No tile_key provided — nothing to mark")
