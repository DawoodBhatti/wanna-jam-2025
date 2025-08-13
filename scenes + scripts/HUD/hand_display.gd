# HandDisplay.gd
extends Control

# Responsible for rendering the current hand based on signals

@onready var game_state := get_node("/root/Gamestate")
@export var card_template_scene: PackedScene
@export var spacing := 380
@export var x_shift := -485.0  # manual horizontal offset for nudging the whole hand

var accepting_input: bool = true  # simple guard to avoid double plays

func _ready() -> void:
	game_state.connect("hand_drawn", Callable(self, "_on_hand_drawn"))
	game_state.connect("play_phase_state_changed", Callable(self, "_on_play_phase_state_changed"))

func _on_hand_drawn(hand: Array) -> void:
	# Clear previous cards
	for child in get_children():
		child.queue_free()
	
	# Render current hand
	for i in range(hand.size()):
		var card_data: Dictionary = hand[i]
		var card_instance: Control = card_template_scene.instantiate()
		if card_instance.has_method("populate"):
			card_instance.populate(card_data)
		# Listen for clicks from this card
		if card_instance.has_signal("card_clicked"):
			card_instance.connect("card_clicked", Callable(self, "_on_card_clicked"))
		card_instance.position = Vector2(x_shift + i * spacing, 0)
		add_child(card_instance)

func _on_card_clicked(card_data: Dictionary) -> void:
	if not accepting_input:
		return
	accepting_input = true  # keep true unless you want to lock during animations
	game_state.request_play_card(card_data)

func _on_play_phase_state_changed(state: String) -> void:
	# Optional UX: disable card interactions when not idle (e.g., during resolve)
	var interactable := state == "Idle"
	_set_hand_interactable(interactable)

func _set_hand_interactable(enabled: bool) -> void:
	# Requires CardTemplate to expose set_interactable; fallback sets mouse_filter
	for child in get_children():
		if child.has_method("set_interactable"):
			child.set_interactable(enabled)
		else:
			if enabled:
				child.mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
