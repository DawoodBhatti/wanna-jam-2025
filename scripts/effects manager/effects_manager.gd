extends Node
class_name EffectsManager

"""
The EffectsManager is the central coordinator for running both instant and queued effects in the game.
It works in tandem with the EffectsQueue (which stores pending effects) and the EffectsRunner (which executes them).

**Queue system:**
- Instant effects are executed immediately and never enter the queue.
- Queued effects are stored in EffectsQueue and processed in order.
- Each queued effect is assigned a unique `queue_id` for tracking.

**Blocking effects:**
- Some effects (e.g., placement or removal) are considered "blocking" because they require an external process to finish
  before the queue can continue.
- When a blocking effect runs, it is stored as `_current_blocking_effect` and the queue pauses.
- The queue resumes only when a `queued_effect_completed(queue_id)` signal is received for that specific blocking effect.
- Non-blocking effects emit `queued_effect_completed` immediately after execution, allowing the queue to continue without waiting.

This design tries to ensure that dependent actions happen in the correct order, prevents race conditions, and cleanly separates
instant execution from queued, potentially asynchronous, operations.
"""

@onready var effects_runner: EffectsRunner = $EffectsRunner
@onready var game_state: GameState = get_node("../GameController/GameState") as GameState

var _current_blocking_effect: Dictionary = {}

# ================================
# 🚀 Lifecycle
# ================================

## Connects relevant signals for queue control and effect completion.
func _ready() -> void:
	SignalBus.connect("end_turn_effects_started", Callable(self, "run_queue"))
	SignalBus.connect("queued_effect_completed", Callable(self, "_on_queued_effect_completed"))
	SignalBus.connect("construction_action_completed", Callable(self, "_on_construction_action_completed"))

# ================================
# 🧱 Effect Context Builder
# ================================

## Builds a complete effect context dictionary from base effect data and extra.
func _build_effect_context(effect: Dictionary, source_type: String, source_id: String, extra_ctx: Dictionary) -> Dictionary:
	var ctx := {
		"effect": effect,
		"source_type": source_type,
		"source_id": source_id
	}
	ctx.merge(extra_ctx, true)
	return ctx

# ================================
# ⚡ Instant Effect Execution
# ================================

## Runs all instant effects for a given source immediately.
func _run_instant_effect(source_type: String, source_id: String, extra_ctx := {}) -> void:
	var effects := _get_effects_from_source(source_type, source_id, "instant_effects")
	for effect in effects:
		if effect.is_empty() or not effect.has("type"):
			continue
		effect["instant"] = true
		var ctx := _build_effect_context(effect, source_type, source_id, extra_ctx)
		effects_runner.run_instant(ctx)

# ================================
# ⏳ Queued Effect Execution
# ================================

## Queues effects for later execution, skipping any marked as instant.
func _queue_effect(source_type: String, source_id: String, key: String, extra_ctx := {}) -> void:
	var effects := _get_effects_from_source(source_type, source_id, key)
	for effect in effects:
		if effect.is_empty() or not effect.has("type"):
			continue
		if effect.get("instant", false):
			push_warning("[EffectsManager] Skipping queue for instant effect: %s" % effect)
			continue
		var ctx := _build_effect_context(effect, source_type, source_id, extra_ctx)
		EffectsQueue.queue_effect(
			func(inner_ctx: Dictionary) -> void:
				effects_runner.run_queued(inner_ctx),
			ctx
		)

# ================================
# 🃏 Public API — Card Effects
# ================================

func run_card_instant_effect(card_id: String) -> void:
	_run_instant_effect("card", card_id)

func queue_card_end_turn_effect(card_id: String) -> void:
	_queue_effect("card", card_id, "end_turn_effects")

func queue_card_remain_effect(card_id: String) -> void:
	_queue_effect("card", card_id, "remain_effects")

# ================================
# 🧱 Public API — Tile Effects
# ================================

func run_tile_instant_effect(tile_id: String, tile_key := "", meta := {}) -> void:
	_run_instant_effect("tile", tile_id, { "tile_key": tile_key, "meta": meta })

func queue_tile_end_turn_effect(tile_id: String, tile_key := "", meta := {}) -> void:
	_queue_effect("tile", tile_id, "end_turn_effects", { "tile_key": tile_key, "meta": meta })

func queue_tile_remain_effect(tile_id: String, tile_key := "", meta := {}) -> void:
	_queue_effect("tile", tile_id, "remain_effects", { "tile_key": tile_key, "meta": meta })

# ================================
# 📦 Source Resolution
# ================================

## Retrieves effects from the relevant catalogue based on source type and key.
func _get_effects_from_source(source_type: String, source_id: String, key: String) -> Array:
	match source_type:
		"card":
			var card := CardCatalogue.get_card_by_id(source_id)
			return card.get(key, []) if not card.is_empty() else []
		"tile":
			var tile := TileCatalogue.get_tile(source_id)
			return tile.get(key, []) if not tile.is_empty() else []
		_:
			push_warning("[EffectsManager] Unknown source type: %s" % source_type)
			return []

# ================================
# 🔄 Queue Drain Logic
# ================================

## Starts draining the queue; emits the finished signal immediately if empty.
func run_queue(finished_signal: String = "end_turn_effects_finished") -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged(finished_signal)
		return
	_process_next()

## Processes the next queued effect or emits the finished signal if empty.
func _process_next() -> void:
	if not EffectsQueue.has_jobs():
		SignalBus.emit_logged("end_turn_effects_finished")
		return

	var job := EffectsQueue.pop_next()
	var cb : Callable = job.get("callable", null)
	var ctx : Dictionary = job.get("context", {})
	var qid : int = ctx.get("queue_id", -1)

	if cb != null and cb.is_valid():
		cb.call(ctx)
	else:
		push_warning("[EffectsManager] Invalid job skipped for queue_id %s" % qid)
		_process_next()

# ================================
# 🔓 Queue Unlock
# ================================

## Handles completion of queued effects, advancing the queue when appropriate.
func _on_queued_effect_completed(queue_id: int) -> void:
	var current_id : int = _current_blocking_effect.get("queue_id", -1)

	# Non-blocking effect: no current blocker
	if _current_blocking_effect.is_empty():
		_process_next()
		return

	# Blocking effect: only advance if IDs match
	if current_id != queue_id:
		return

	_current_blocking_effect = {}
	_process_next()

# ================================
# 🛠 External Completion Handler
# ================================

## Handles external completion signals (e.g., construction) for blocking effects.
func _on_construction_action_completed(mode: String, data: Dictionary, count: int) -> void:
	if _current_blocking_effect.is_empty():
		return

	var queue_id : int = _current_blocking_effect.get("queue_id", -1)
	if queue_id == -1:
		return

	SignalBus.emit_logged("queued_effect_completed", queue_id)
