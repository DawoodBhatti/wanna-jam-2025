extends Label

@onready var game_state: GameState = get_node("/root/Gamestate")
var tween: Tween

func _ready() -> void:
	# Listen for turn number changes
	game_state.connect("turn_ended", Callable(self, "_on_turn_ended"))
	game_state.connect("game_started", Callable(self, "_on_game_started"))

	# Basic styling (match DrawPile)
	var font := ThemeDB.fallback_font
	add_theme_font_override("font", font)
	add_theme_constant_override("outline_size", 3)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_color_override("font_color", Color.WHITE)

func _on_game_started() -> void:
	_update_turn_label(game_state.current_turn)

func _on_turn_ended(turn_number: int) -> void:
	# turn_number is the one that just ended, so display the *next* turn
	_update_turn_label(turn_number + 1)

func _update_turn_label(turn_number: int) -> void:
	text = "Turn: " + str(turn_number)
	visible = true

	# Flash orange
	add_theme_color_override("font_color", Color("#ff9900"))  # bright orange
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		self,
		"theme_override_colors/font_color",
		Color.WHITE,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
