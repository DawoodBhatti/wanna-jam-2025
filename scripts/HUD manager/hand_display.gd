extends Control
# Responsible for rendering the current hand based on GameState signals

@export var spacing: float = 380.0
@export var x_shift: float = -485.0

var accepting_input: bool = true
var card_template: Control  # prototype fetched from DeckManager

func _ready() -> void:
	await get_tree().process_frame
	#allow frame to pass so we completely load CardTemplate's children
	
	# Fetch the template via DeckManager's API
	var deck_manager = get_node("../../DeckManager")
	card_template = deck_manager.get_card_template()


	# Connect signals
	SignalBus.connect("hand_drawn", Callable(self, "_on_hand_drawn"))
	SignalBus.connect("play_phase_state_changed", Callable(self, "_on_play_phase_state_changed"))
	SignalBus.connect("card_played", Callable(self, "_on_card_played"))

	print("[HandDisplay] ready!")

func _on_hand_drawn(hand: Array) -> void:
	# Clear previous hand
	for child in get_children():
		child.queue_free()

	# Spawn cards from prototype
	for i in range(hand.size()):
		var card_data: Dictionary = hand[i]
		var card_instance := card_template.duplicate()

		if card_instance.has_method("populate"):
			card_instance.populate(card_data)

		if card_instance.has_signal("card_clicked"):
			card_instance.connect("card_clicked", Callable(self, "_on_card_clicked"))

		card_instance.position = Vector2(x_shift + i * spacing, 0)
		add_child(card_instance)

func _on_card_clicked(card_data: Dictionary) -> void:
	if not accepting_input:
		return
	accepting_input = false
	SignalBus.emit_logged("card_clicked", [card_data])

func _on_play_phase_state_changed(state: String) -> void:
	var interactable: bool = (state == "Idle")
	_set_hand_interactable(interactable)
	if interactable:
		accepting_input = true

func _set_hand_interactable(enabled: bool) -> void:
	for child in get_children():
		if child.has_method("set_interactable"):
			child.set_interactable(enabled)
		else:
			child.mouse_filter = (
				Control.MOUSE_FILTER_PASS if enabled
				else Control.MOUSE_FILTER_IGNORE
			)

func _on_card_played(card_data: Dictionary) -> void:
	for child in get_children():
		if child.has_method("fade_out") and child.card_data == card_data:
			child.fade_out()
			break
	accepting_input = true
