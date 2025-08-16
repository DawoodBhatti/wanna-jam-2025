extends Control

signal card_clicked(card_data: Dictionary)

var card_data: Dictionary
var hover_offset: Vector2 = Vector2(0, -200)
var original_position: Vector2 = Vector2.ZERO
var tween: Tween
var interactable: bool = true

func _ready() -> void:
	original_position = position
	set_mouse_filter(Control.MOUSE_FILTER_PASS)
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("gui_input", Callable(self, "_on_gui_input"))

func populate(data: Dictionary) -> void:
	card_data = data

	$CardTitle.text = data.name
	$CardDescription.text = data.description

	if typeof(data.cost) == TYPE_INT:
		if data.cost == 0:
			$CardCost.text = "Free"
		else:
			$CardCost.text = str(data.cost) + " Cost"

	if data.has("image_path"):
		if data.image_path != "":
			var tex: Resource = load(data.image_path)
			if tex is Texture2D:
				$CardImage.texture = tex

	# Ensure the material is unique per instance (prevents cross-card fading)
	if $CardImage.material is ShaderMaterial:
		var sm: ShaderMaterial = $CardImage.material
		$CardImage.material = sm.duplicate(true)

	print("Card populated:", data.name)

func _on_mouse_entered() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position + hover_offset, 0.5)
	z_index = 1

func _on_mouse_exited() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.5)
	z_index = 0

func _on_gui_input(event: InputEvent) -> void:
	if not interactable:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			print("Card clicked:", card_data.name)
			emit_signal("card_clicked", card_data)

func set_interactable(value: bool) -> void:
	interactable = value
	if interactable:
		mouse_filter = Control.MOUSE_FILTER_PASS
		modulate = Color(1, 1, 1)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color(0.8, 0.8, 0.8)

func fade_out(duration: float = 0.4) -> void:
	set_interactable(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ft: Tween = create_tween()

	# Fade entire Control
	ft.tween_property(self, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Fade shader uniform (assumes your shader has: uniform float fade = 1.0;)
	var mat: Material = $CardImage.material
	if mat is ShaderMaterial:
		var sm: ShaderMaterial = mat
		var start_fade: float = 1.0
		# Try to read current value if present; if not, start from 1.0
		var current : float = sm.get_shader_parameter("fade")
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
