extends Control
# 🎴 Responsible for rendering and managing the current hand

@onready var game_state: GameState = get_node("/root/Main/GameController/GameState")

@export var spacing: float = 380.0
@export var x_shift: float = -485.0

var accepting_input: bool = true
var CardTemplateScene: PackedScene = preload("res://scenes/cards/card_template.tscn")

func _ready() -> void:
	SignalBus.connect("hand_drawn", Callable(self, "_on_hand_drawn"))
	SignalBus.connect("inner_phase_changed", Callable(self, "_on_inner_phase_changed"))
	SignalBus.connect("card_was_played", Callable(self, "_on_card_was_played"))
	SignalBus.connect("hand_resolved", Callable(self, "_on_hand_resolved"))


#renders hand on screen after hand drawn signal is received
func _on_hand_drawn(hand: Array) -> void:
	_clear_hand(true)

	if game_state.current_turn > 0:
		await get_tree().create_timer(0.7).timeout

	for i in range(hand.size()):
		var card_id: String = hand[i]
		var card_data: Dictionary = CardCatalogue.get_card_by_id(card_id)
		var card_instance: Control = CardTemplateScene.instantiate()

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

#let the hand be interactable once we start playing 
func _on_inner_phase_changed(new_phase: String) -> void:
	var interactable: bool = (new_phase == "playing") 
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

func _on_card_was_played(card_id: String) -> void:
	var card_data := CardCatalogue.get_card_by_id(card_id)
	for child in get_children():
		if child.has_method("fade_out") and child.card_data == card_data:
			child.fade_out()
			break
	accepting_input = true

func _on_hand_resolved() -> void:
	_clear_hand(true)
	accepting_input = false

func _clear_hand(animated: bool = false) -> void:
	for child in get_children():
		if animated and child.has_method("fade_out"):
			child.fade_out()
		else:
			child.queue_free()
