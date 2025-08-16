extends Resource
class_name StructureSpec

# ------------------------------------------------------------------------------
# StructureSpec.gd
#
# Purpose:
#   Data-driven blueprint (Resource) defining the behaviour and metadata for a
#   specific type of structure in the game. Acts as a template rather than an
#   in-world instance.
#
# Key Fields:
#   id            - Internal identifier for this structure type (e.g. "medusa").
#   name          - Friendly display name for UI and debugging.
#   priority      - Determines resolution order when multiple effects trigger;
#                   lower values resolve earlier.
#   effect_script - Script resource implementing `apply_effect(ctx, pos)`; this
#                   is instantiated and executed when the structure resolves.
#   aoe_shape     - Descriptive label of the effect’s area-of-effect shape
#                   (e.g. "self", "ring", "cross"). Currently informational only.
#
# How It Works:
#   At runtime, a StructureManager or similar system will:
#     1. Retrieve the StructureSpec linked to an in-world structure.
#     2. Call spec.apply(ctx, pos) with a ready-to-use EffectContext.
#     3. StructureSpec instantiates its `effect_script` and runs `apply_effect`.
#
# Benefits:
#   - Keeps structure logic modular and decoupled from core systems.
#   - Enables designers to tweak and swap effects without code changes.
#   - Supports a library of reusable structure types defined entirely in assets.
# ------------------------------------------------------------------------------

@export var id: String = ""             # e.g. "stone", "medusa"
@export var name: String = ""
@export var priority: int = 0           # lower = earlier in resolution order
@export var effect_script: Script       # Script with apply_effect(ctx, pos)
@export var aoe_shape: String = "self"  # purely descriptive for now


func apply(ctx: EffectContext, pos: Vector2i) -> void:
	if effect_script:
		var eff = effect_script.new()
		if eff.has_method("apply_effect"):
			eff.apply_effect(ctx, pos)
