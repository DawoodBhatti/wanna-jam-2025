extends Label

var tween: Tween  # declared, but not created until needed

func _ready() -> void:
	SignalBus.connect("piles_changed", Callable(self, "_on_piles_changed"))

	# Outline styling
	var font := ThemeDB.fallback_font
	add_theme_font_override("font", font)
	add_theme_constant_override("outline_size", 3)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_color_override("font_color", Color.WHITE)

func _on_piles_changed(deck_size: int, _hand_size: int, _discard_size: int) -> void:
	text = "Deck: " + str(deck_size)
	visible = true

	# Flash light blue
	add_theme_color_override("font_color", Color("#88ccff"))

	if tween:
		tween.kill()  # stop any in‑flight animation

	tween = create_tween()
	tween.tween_property(
		self,
		"theme_override_colors/font_color",
		Color.WHITE,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
