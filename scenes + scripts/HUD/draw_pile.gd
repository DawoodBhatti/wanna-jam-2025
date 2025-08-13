extends Control

@onready var game_state := get_node("/root/Gamestate")

func _ready() -> void:
	game_state.connect("piles_changed", Callable(self, "_on_piles_changed"))

func _on_piles_changed(deck_size: int, _hand_size: int, _discard_size: int) -> void:
	if deck_size <= 0:
		print("nothing in draw pile")
		visible = false
	else:
		print(str(deck_size) + " cards in draw pile")
		visible = true
