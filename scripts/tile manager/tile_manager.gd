extends Node
class_name TileManager

@onready var effects_manager: EffectsManager = get_node("../EffectsManager") as EffectsManager

func _ready() -> void:
	# When GameState enters "Turn Effects", it emits this request.
	SignalBus.connect("queue_end_turn_tile_effects", Callable(self, "_on_queue_end_turn_tile_effects"))


func _on_queue_end_turn_tile_effects() -> void:
	var tiles: Array = _get_active_tiles()
	for tile: Dictionary in tiles:
		var meta := tile.get("meta", {}) as Dictionary
		var tile_id: String = meta.get("tile_name", "")
		if tile_id == "":
			continue
		var tile_key: String = tile.get("key", "")
		effects_manager.queue_tile_end_turn_effect(tile_id, tile_key, meta)

	SignalBus.emit_logged("end_turn_tile_effects_queued")


# Integration with tile state to list active tiles.
func _get_active_tiles() -> Array:
	return TileState.get_unfired_tiles()
