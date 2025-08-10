# Camera2D.gd
extends Camera2D

# --- Zoom settings ---
const MIN_ZOOM := 0.5           # smaller = zoom in further
const MAX_ZOOM := 6.0           # larger = zoom out more
const ZOOM_FACTOR := 1.15       # per wheel step (>1 zooms out, <1 zooms in)
const ZOOM_SMOOTH := 0.18       # 0..1, how quickly we approach target zoom

# --- Pan settings ---
const PAN_SPEED := 900.0        # pixels per second at zoom = 1

var target_zoom: Vector2 = Vector2(2.011357, 2.011357)
var dragging := false

# TODO:
# camera reset with r

func _ready() -> void:
	zoom = target_zoom
	# Optional: Set camera world limits here if you have them
	# limit_left = 0; limit_top = 0; limit_right = 4096; limit_bottom = 4096

func _unhandled_input(event: InputEvent) -> void:
	# --- Mouse wheel zoom ---
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(target_zoom * (ZOOM_FACTOR)) # zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(target_zoom * (1.0 / ZOOM_FACTOR))         # zoom out

	# --- Middle-mouse drag start/stop ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		dragging = event.pressed

	# --- Drag while moving ---
	if event is InputEventMouseMotion and dragging:
		# event.relative is in screen pixels; divide by zoom for consistent pan speed
		position -= event.relative / zoom.x

func _process(delta: float) -> void:
	# Smoothly approach target zoom
	if zoom != target_zoom:
		zoom = zoom.lerp(target_zoom, ZOOM_SMOOTH)

	# Optional keyboard panning – set actions in Project Settings → Input Map
	var move := Vector2.ZERO
	# Example:
	# if Input.is_action_pressed("camera_left"):  move.x -= 1
	# if Input.is_action_pressed("camera_right"): move.x += 1
	# if Input.is_action_pressed("camera_up"):    move.y -= 1
	# if Input.is_action_pressed("camera_down"):  move.y += 1

	if move != Vector2.ZERO:
		position += move.normalized() * (PAN_SPEED * delta) / zoom.x

func _set_zoom(next: Vector2) -> void:
	var z := clampf(next.x, MIN_ZOOM, MAX_ZOOM)
	target_zoom = Vector2(z, z)
	print(target_zoom)
