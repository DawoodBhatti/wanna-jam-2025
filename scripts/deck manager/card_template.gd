extends Control

# 🃏 Card_template: Handles visual behavior and interaction for individual cards
# should probably move to the HUD?


var card_data: Dictionary
var hover_offset: Vector2 = Vector2(0, -200)
var original_position: Vector2 = Vector2.ZERO
var tween: Tween = null
var interactable: bool = true

# -------------------------------------------------------------------
# 🚦 Initialization
# -------------------------------------------------------------------
func _ready() -> void:
	original_position = position
	set_mouse_filter(Control.MOUSE_FILTER_PASS)

	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("gui_input", Callable(self, "_on_gui_input"))

# -------------------------------------------------------------------
# 📦 Populate Card Visuals
# -------------------------------------------------------------------
func populate(data: Dictionary) -> void:
	card_data = data

	var title_label: Label = $CardTitle
	var description_label: Label = $CardDescription
	var cost_label: Label = $CardCost
	var image_texture_rect: TextureRect = $CardImage

	title_label.text = card_data.name
	description_label.text = card_data.description

	if typeof(card_data.cost) == TYPE_INT:
		if card_data.cost == 0:
			cost_label.text = "Free"
		else:
			cost_label.text = str(card_data.cost) + " Cost"

	if card_data.has("image_path") and card_data.image_path != "":
		var tex: Resource = load(card_data.image_path)
		if tex is Texture2D:
			image_texture_rect.texture = tex

	# Ensure unique shader material per instance
	if image_texture_rect.material is ShaderMaterial:
		var sm: ShaderMaterial = image_texture_rect.material
		image_texture_rect.material = sm.duplicate(true)

# -------------------------------------------------------------------
# 🖱️ Hover Effects
# -------------------------------------------------------------------
func _on_mouse_entered() -> void:
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position + hover_offset, 0.5)
	z_index = 1

func _on_mouse_exited() -> void:
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.5)
	z_index = 0

# -------------------------------------------------------------------
# 🖱️ Click Interaction
# -------------------------------------------------------------------
func _on_gui_input(event: InputEvent) -> void:
	if not interactable:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			print("Card clicked:", card_data.name)
			SignalBus.emit_logged("card_clicked", card_data.get("id", ""))

# -------------------------------------------------------------------
# 🔒 Interactability Toggle
# -------------------------------------------------------------------
func set_interactable(value: bool) -> void:
	interactable = value

	if interactable:
		mouse_filter = Control.MOUSE_FILTER_PASS
		modulate = Color(1.0, 1.0, 1.0)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color(0.8, 0.8, 0.8)

# -------------------------------------------------------------------
# 🌫️ Fade Out & Cleanup
# -------------------------------------------------------------------
func fade_out(duration: float = 0.4) -> void:
	set_interactable(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ft: Tween = create_tween()

	# Fade entire Control
	ft.tween_property(self, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Fade shader uniform (assumes: uniform float fade = 1.0)
	var mat: Material = $CardImage.material
	if mat is ShaderMaterial:
		var sm: ShaderMaterial = mat
		var start_fade: float = 1.0
		var current: Variant = sm.get_shader_parameter("fade")

		if typeof(current) == TYPE_FLOAT:
			start_fade = float(current)

		ft.parallel().tween_method(
			func(v: float) -> void:
				if is_instance_valid(sm):
					sm.set_shader_parameter("fade", v),
			start_fade, 0.0, duration
		).set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_OUT)

	ft.tween_callback(Callable(self, "queue_free"))
