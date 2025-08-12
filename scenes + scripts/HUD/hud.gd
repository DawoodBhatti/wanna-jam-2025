# res://ui/hud.gd
extends Node

@onready var stone_label: Label = %StoneCount
@onready var wood_label: Label = %WoodCount
@onready var food_label: Label = %FoodCount
@onready var pop_label: Label = %PopCount


func _ready() -> void:
	# Connect to signals in the autoload singleton named "Resources"
	Resources.stone_changed.connect(_on_stone_changed)
	Resources.wood_changed.connect(_on_wood_changed)
	Resources.food_changed.connect(_on_food_changed)
	Resources.pop_changed.connect(_on_pop_changed)
	# Draw initial values
	_refresh_all()


func _refresh_all() -> void:
	stone_label.text = str(Resources.stone_count)
	wood_label.text  = str(Resources.wood_count)
	food_label.text  = str(Resources.food_count)
	pop_label.text   = str(Resources.pop_count)


func _on_stone_changed(_amount: int) -> void:
	stone_label.text = str(Resources.stone_count)


func _on_wood_changed(_amount: int) -> void:
	wood_label.text = str(Resources.wood_count)


func _on_food_changed(_amount: int) -> void:
	food_label.text = str(Resources.food_count)


func _on_pop_changed(_amount: int) -> void:
	pop_label.text = str(Resources.pop_count)
