extends Label

var tween: Tween   # declare but don’t create until needed

func _ready() -> void:
	SignalBus.connect("piles_changed", Callable(self, "_on_piles_changed"))

	# Outline styling
	var font := ThemeDB.fallback_font
	add_theme_font_override("font", font)
	add_theme_constant_override("outline_size", 3)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_color_override("font_color", Color.WHITE)

func _on_piles_changed(_deck_size: int, _hand_size: int, discard_size: int) -> void:
	text = "Discard: " + str(discard_size)
	visible = true

	# Flash red
	add_theme_color_override("font_color", Color("#ff4444"))

	if tween:
		tween.kill()  # stop any existing animation

	tween = create_tween()
	tween.tween_property(
		self,
		"theme_override_colors/font_color",
		Color.WHITE,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
