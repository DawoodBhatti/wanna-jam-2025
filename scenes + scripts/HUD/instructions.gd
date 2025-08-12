extends Label

@onready var instructions: Label = %Instructions
var instructions_visible := true

func _ready():
	update_instructions()

func _process(delta):
	if Input.is_action_just_pressed("toggle_instructions"):
		print("toggling")
		instructions_visible = !instructions_visible
		instructions.visible = instructions_visible

func update_instructions():
	var text := "🎮 Controls:\n\n"
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"):
			continue # Skip built-in UI actions
		var keys = get_action_bindings(action_name)
		if keys != "":
			text += "%s → %s\n" % [action_name, keys]
	instructions.text = text

func get_action_bindings(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	var keys := []
	for event in events:
		if event is InputEventKey:
			keys.append(OS.get_keycode_string(event.physical_keycode))
		elif event is InputEventMouseButton:
			keys.append("Mouse Button %d" % event.button_index)
		elif event is InputEventJoypadButton:
			keys.append("Joypad Button %d" % event.button_index)
		else:
			keys.append("Other Input")
	return ", ".join(keys)
