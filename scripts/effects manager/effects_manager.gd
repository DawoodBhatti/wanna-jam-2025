extends Node
class_name EffectsManager

@onready var effects_runner: EffectsRunner = $EffectsRunner

# =========================================================
# 🚀 Lifecycle
# =========================================================
func _ready() -> void:
	# Listen for the signal that starts draining queued end-turn effects
	SignalBus.connect("end_turn_effects_started", Callable(self, "run_queue"))

# =========================================================
# 🛠 Internal helper — Build a full effect execution context
# =========================================================
## Creates the context dictionary that will be passed to EffectsRunner.
## This context always contains:
##   - "effect": the effect definition dictionary (from catalogue or other source)
##   - "source_type": originator of the effect ("card", "tile", or other systems)
##   - "source_id": the ID used to look up the definition
## Plus any extra fields from `extra_ctx` (e.g. "tile_key" and "meta" for tiles).
##
## Why extra_ctx?
##   For cards, we don't need anything extra — it's just {}.
##   For tiles, we pass:
##       { "tile_key": <composite key>, "meta": <parsed key dict> }
##   so that custom effects (like square_petrify) know exactly which tile
##   instance they are acting on and can update TileState accordingly.
##
## Extensibility:
##   This design also allows you to support effects from other originators
##   such as characters, weather systems, environmental hazards, etc.
##   You can pass any additional context those systems need via `extra_ctx`
##   and identify them with a new `source_type` string.
func _build_effect_context(effect: Dictionary, source_type: String, source_id: String, extra_ctx: Dictionary) -> Dictionary:
	var ctx := {
		"effect": effect,
		"source_type": source_type,
		"source_id": source_id
	}
	ctx.merge(extra_ctx, true) # merge originator-specific context if provided
	return ctx

# =========================================================
# ⚡ Run all instant effects for a given source immediately
# =========================================================
## Looks up all "instant_effects" for the given source (card/tile/other),
## builds a context for each, and runs them immediately via EffectsRunner.
##
## For tiles, extra_ctx will include tile_key/meta so the effect knows
## which board instance it belongs to.
## For other originators (characters, weather, etc.), extra_ctx can carry
## whatever positional or state data they require.
func _run_instant_effect(source_type: String, source_id: String, extra_ctx := {}) -> void:
	var effects: Array = _get_effects_from_source(source_type, source_id, "instant_effects")
	for effect: Dictionary in effects:
		if effect.is_empty() or not effect.has("type"):
			continue
		var e: Dictionary = effect.duplicate(true)
		e["instant"] = true
		var ctx := _build_effect_context(e, source_type, source_id, extra_ctx)
		effects_runner.run_instant(ctx)

# =========================================================
# ⏳ Queue all effects of a given type for later execution
# =========================================================
## Looks up all effects for the given key ("end_turn_effects", "remain_effects", etc.),
## builds a context for each, and queues them in EffectsQueue.
##
## For tiles, extra_ctx will include tile_key/meta so the effect knows
## which board instance it belongs to when it eventually runs.
## For other originators (characters, weather, etc.), extra_ctx can carry
## whatever positional or state data they require.
func _queue_effect(source_type: String, source_id: String, key: String, extra_ctx := {}) -> void:
	var effects: Array = _get_effects_from_source(source_type, source_id, key)
	for effect: Dictionary in effects:
		if effect.is_empty() or not effect.has("type"):
			continue
		var ctx := _build_effect_context(effect, source_type, source_id, extra_ctx)
		EffectsQueue.queue_effect(
			func(inner_ctx: Dictionary) -> void:
				effects_runner.run_queued(inner_ctx),
			ctx
		)

# =========================================================
# 🃏 Public API — Card‑Specific Wrappers
# =========================================================
func run_card_instant_effect(card_id: String) -> void:
	_run_instant_effect("card", card_id)

func queue_card_end_turn_effect(card_id: String) -> void:
	_queue_effect("card", card_id, "end_turn_effects")

func queue_card_remain_effect(card_id: String) -> void:
	_queue_effect("card", card_id, "remain_effects")

# =========================================================
# 🧱 Public API — Tile‑Specific Wrappers
# =========================================================
func run_tile_instant_effect(tile_id: String, tile_key := "", meta := {}) -> void:
	_run_instant_effect("tile", tile_id, { "tile_key": tile_key, "meta": meta })

func queue_tile_end_turn_effect(tile_id: String, tile_key := "", meta := {}) -> void:
	_queue_effect("tile", tile_id, "end_turn_effects", { "tile_key": tile_key, "meta": meta })

func queue_tile_remain_effect(tile_id: String, tile_key := "", meta := {}) -> void:
	_queue_effect("tile", tile_id, "remain_effects", { "tile_key": tile_key, "meta": meta })

# =========================================================
# 📦 Source Resolution
# =========================================================
## Looks up the definition for a card/tile/other originator and returns the requested effect list.
func _get_effects_from_source(source_type: String, source_id: String, key: String) -> Array:
	match source_type:
		"card":
			var card: Dictionary = CardCatalogue.get_card_by_id(source_id)
			if card.is_empty():
				push_warning("[EffectsManager] Unknown card ID: %s" % source_id)
				return []
			return card.get(key, []) as Array
		"tile":
			var tile: Dictionary = TileCatalogue.get_tile(source_id)
			if tile.is_empty():
				push_warning("[EffectsManager] Unknown tile ID: %s" % source_id)
				return []
			return tile.get(key, []) as Array
		_:
			# For other originators (characters, weather, etc.), add your own lookup logic here
			push_warning("[EffectsManager] Unknown source type: %s" % source_type)
			return []

# =========================================================
# 🔄 Queue Processing
# =========================================================
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

func notify_effect_done() -> void:
	_process_next()
