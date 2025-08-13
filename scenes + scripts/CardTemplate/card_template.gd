extends Control

#this script is a template for individual cards
#it specifies the contents of the card (such as title, cost, etc)
#and describes the movements and behaviour also

signal card_clicked(card_data: Dictionary)

var card_data: Dictionary
var hover_offset := Vector2(0, -200)
var original_position := Vector2.ZERO
var tween: Tween  # created via create_tween()
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
			var tex := load(data.image_path)
			if tex is Texture2D:
				$CardImage.texture = tex
		
	print("Card populated:", data.name)


func _on_mouse_entered():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position + hover_offset, 0.5)
	z_index = 1


func _on_mouse_exited():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.5)
	z_index = 0


func _on_gui_input(event: InputEvent) -> void:
	if not interactable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Card clicked:", card_data.name)
		emit_signal("card_clicked", card_data)
		
		
func set_interactable(value: bool) -> void:
	interactable = value
	# Visual feedback and input gating
	if interactable:
		mouse_filter = Control.MOUSE_FILTER_PASS
		modulate = Color(1, 1, 1)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color(0.8, 0.8, 0.8)
