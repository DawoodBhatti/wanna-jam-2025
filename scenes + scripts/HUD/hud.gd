# res://ui/hud.gd
extends Node

# HUD is responsible for resource labels and instantiating DeckManager (optional)
@onready var stone_label: Label = %StoneCount
@onready var wood_label: Label = %WoodCount
@onready var food_label: Label = %FoodCount
@onready var pop_label: Label = %PopCount

@onready var hand_display := $HandDisplay
@onready var draw_display := $DrawPile
@onready var discard_display := $DiscardPile
@onready var deck_manager := get_node("/root/main/DeckManager")
@onready var game_state := get_node("/root/Gamestate")  # Autoload singleton
@onready var end_turn_button: Button = $EndTurn   # End Turn UI button


func _ready() -> void:
	# Connect to signals in the autoload singleton named "Resources"
	GameResources.stone_changed.connect(_on_stone_changed)
	GameResources.wood_changed.connect(_on_wood_changed)
	GameResources.food_changed.connect(_on_food_changed)
	GameResources.pop_changed.connect(_on_pop_changed)
	
	# Wire up End Turn button
	end_turn_button.connect("pressed", Callable(self, "_on_end_turn_pressed"))
	_apply_end_turn_button_style()
	
	# React to phase changes to show/enable button during Play phase only
	if game_state:
		game_state.connect("phase_changed", Callable(self, "_on_phase_changed"))
	
	# Draw initial values
	_refresh_all()


func _refresh_all() -> void:
	stone_label.text = str(GameResources.stone_count)
	wood_label.text  = str(GameResources.wood_count)
	food_label.text  = str(GameResources.food_count)
	pop_label.text   = str(GameResources.pop_count)


func _on_stone_changed(_amount: int) -> void:
	stone_label.text = str(GameResources.stone_count)


func _on_wood_changed(_amount: int) -> void:
	wood_label.text = str(GameResources.wood_count)


func _on_food_changed(_amount: int) -> void:
	food_label.text = str(GameResources.food_count)


func _on_pop_changed(_amount: int) -> void:
	pop_label.text = str(GameResources.pop_count)


func _on_end_turn_pressed() -> void:
	# Tell GameState to move on from Play; prefer owned logic if available
	if game_state and game_state.has_method("advance_phase"):
		game_state.advance_phase()
	else:
		# Fallback: emit intention (if your flow listens for this)
		if game_state and game_state.has_signal("play_phase_ended"):
			game_state.emit_signal("play_phase_ended")


func _on_phase_changed(new_phase: String) -> void:
	# Only show/enable End Turn during the Play phase
	var is_play := (new_phase == "Play")
	end_turn_button.visible = is_play
	end_turn_button.disabled = not is_play


func _apply_end_turn_button_style() -> void:
	end_turn_button.theme = null  # break from parent theme

	# Colors
	var red_bg := Color("#aa000746")      # deep red background
	var red_text := Color("#aa0007e3")    # brighter red for hover/pressed text
	var grey_bg := Color("#dddddd")       # light grey background
	var faded_red := Color("#55002323")   # disabled background

	# Normal: red background
	var normal := StyleBoxFlat.new()
	normal.bg_color = red_bg
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8

	# Hover + Pressed: grey background
	var hover := normal.duplicate()
	hover.bg_color = grey_bg

	var pressed := normal.duplicate()
	pressed.bg_color = grey_bg

	# Disabled: faded red background
	var disabled := normal.duplicate()
	disabled.bg_color = faded_red

	end_turn_button.add_theme_stylebox_override("normal", normal)
	end_turn_button.add_theme_stylebox_override("hover", hover)
	end_turn_button.add_theme_stylebox_override("pressed", pressed)
	end_turn_button.add_theme_stylebox_override("disabled", disabled)

	# Assign font so per-state colors are respected
	end_turn_button.add_theme_font_override("font", ThemeDB.fallback_font)

	# Font colors
	end_turn_button.add_theme_color_override("font_color", Color.WHITE)         # normal: white text on red
	end_turn_button.add_theme_color_override("font_hover_color", red_text)      # hover: bright red text on grey
	end_turn_button.add_theme_color_override("font_pressed_color", red_text)    # pressed: bright red text on grey
	end_turn_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))  # faded white
