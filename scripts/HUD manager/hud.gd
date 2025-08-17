# res://ui/hud.gd
extends Node

@onready var stone_label: Label = %StoneCount
@onready var wood_label: Label = %WoodCount
@onready var food_label: Label = %FoodCount
@onready var pop_label: Label  = %PopCount

@onready var hand_display := $HandDisplay
@onready var draw_display := $DrawPile
@onready var discard_display := $DiscardPile
@onready var end_turn_button: Button = $EndTurn


func _ready() -> void:
	# Bind resource labels in one consistent way
	_bind_resource_label("stone_changed", stone_label, func(): return ResourceState.stone_count)
	_bind_resource_label("wood_changed",  wood_label,  func(): return ResourceState.wood_count)
	_bind_resource_label("food_changed",  food_label,  func(): return ResourceState.food_count)
	_bind_resource_label("pop_changed",   pop_label,   func(): return ResourceState.pop_count)
	
	end_turn_button.connect("pressed", Callable(self, "_on_end_turn_pressed"))
	_apply_end_turn_button_style()

	SignalBus.connect("phase_changed", Callable(self, "_on_phase_changed"))
	
	_refresh_all()


func _bind_resource_label(signal_name: String, label: Label, value_getter: Callable) -> void:
	# Note: lambda must use a valid parameter name; '_' alone is not allowed in GDScript 4
	SignalBus.connect(signal_name, func(_value): label.text = str(value_getter.call()))


func _refresh_all() -> void:
	stone_label.text = str(ResourceState.stone_count)
	wood_label.text  = str(ResourceState.wood_count)
	food_label.text  = str(ResourceState.food_count)
	pop_label.text   = str(ResourceState.pop_count)


func _on_end_turn_pressed() -> void:
	SignalBus.emit_logged("hand_resolved")

#not needed
#func _on_phase_changed(new_phase: String) -> void:
	#var is_play := (new_phase == "Play")
	#end_turn_button.visible = is_play
	#end_turn_button.disabled = not is_play


func _apply_end_turn_button_style() -> void:
	end_turn_button.theme = null

	var red_bg := Color("#aa000746")
	var red_text := Color("#aa0007e3")
	var grey_bg := Color("#dddddd")
	var faded_red := Color("#55002323")

	var normal := StyleBoxFlat.new()
	normal.bg_color = red_bg
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8

	var hover := normal.duplicate()
	hover.bg_color = grey_bg

	var pressed := normal.duplicate()
	pressed.bg_color = grey_bg

	var disabled := normal.duplicate()
	disabled.bg_color = faded_red

	end_turn_button.add_theme_stylebox_override("normal", normal)
	end_turn_button.add_theme_stylebox_override("hover", hover)
	end_turn_button.add_theme_stylebox_override("pressed", pressed)
	end_turn_button.add_theme_stylebox_override("disabled", disabled)

	end_turn_button.add_theme_font_override("font", ThemeDB.fallback_font)
	end_turn_button.add_theme_color_override("font_color", Color.WHITE)
	end_turn_button.add_theme_color_override("font_hover_color", red_text)
	end_turn_button.add_theme_color_override("font_pressed_color", red_text)
	end_turn_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
