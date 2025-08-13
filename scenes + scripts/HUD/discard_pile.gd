extends Control

@onready var game_state := get_node("/root/Gamestate")

func _ready() -> void:
	game_state.connect("piles_changed", Callable(self, "_on_piles_changed"))

func _on_piles_changed(_deck_size: int, _hand_size: int, discard_size: int) -> void:
	if discard_size <= 0:
		print("nothing in discard pile")
		visible = false
	else:
		print(str(discard_size) + " cards in discard pile")
		visible = true
