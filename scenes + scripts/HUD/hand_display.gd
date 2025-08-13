extends Control
# Responsible for rendering the current hand based on GameState signals

@onready var game_state: Gamestate = Gamestate   # Direct autoload reference
@export var card_template_scene: PackedScene
@export var spacing: float = 380.0
@export var x_shift: float = -485.0  # horizontal offset for hand layout

var accepting_input: bool = true  # guard against rapid/double clicks


func _ready() -> void:
	# Listen for hand refresh
	game_state.connect("hand_drawn", Callable(self, "_on_hand_drawn"))
	# Listen for phase changes (toggle interactivity)
	game_state.connect("play_phase_state_changed", Callable(self, "_on_play_phase_state_changed"))
	# Listen for card plays (fade + remove)
	game_state.connect("card_played", Callable(self, "_on_card_played"))


func _on_hand_drawn(hand: Array) -> void:
	# Clear previous hand
	for child in get_children():
		child.queue_free()

	# Lay out new cards
	for i in range(hand.size()):
		var card_data: Dictionary = hand[i]
		var card_instance: Control = card_template_scene.instantiate()

		if card_instance.has_method("populate"):
			card_instance.populate(card_data)

		# Connect click once
		if card_instance.has_signal("card_clicked"):
			card_instance.connect("card_clicked", Callable(self, "_on_card_clicked"))

		card_instance.position = Vector2(x_shift + i * spacing, 0)
		add_child(card_instance)


func _on_card_clicked(card_data: Dictionary) -> void:
	if not accepting_input:
		return
	# Block further clicks until we unlock
	accepting_input = false
	game_state.request_play_card(card_data)


func _on_play_phase_state_changed(state: String) -> void:
	var interactable: bool = (state == "Idle")
	_set_hand_interactable(interactable)
	# Also reset click guard when returning to Idle
	if interactable:
		accepting_input = true


func _set_hand_interactable(enabled: bool) -> void:
	for child in get_children():
		if child.has_method("set_interactable"):
			child.set_interactable(enabled)
		else:
			if enabled:
				child.mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_card_played(card_data: Dictionary) -> void:
	# Fade/remove card from hand
	for child in get_children():
		if child.has_method("fade_out") and child.card_data == card_data:
			child.fade_out()
			break
	# Unlock clicks after this card’s fade has started
	accepting_input = true
