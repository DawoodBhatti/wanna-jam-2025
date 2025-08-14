extends Node
class_name StructureManager

signal structure_placed(data)
signal structure_recycled(data)
signal tile_effects_done   # reports back to GameState when effects finish

var _instances: Array[Dictionary] = []
var _by_pos: Dictionary = {}
var _placed_counter: int = 0

@export var place_cost_on_success: bool = true

@onready var base_grid: Node = %Tiles
@onready var game_state: Node = get_node("/root/Gamestate")
@onready var resources: Node = get_node("/root/GameResources")

func _ready() -> void:
	# BaseGrid — tile activity and mode lifecycle
	base_grid.connect("structure_tile_placed", Callable(self, "_on_tile_placed"))
	base_grid.connect("structure_tile_erased", Callable(self, "_on_tile_erased"))
	base_grid.connect("place_mode_completed", Callable(self, "_on_place_mode_completed"))
	base_grid.connect("remove_mode_completed", Callable(self, "_on_remove_mode_completed"))

	# GameState — requests to enter modes and global cancels
	game_state.connect("structure_placement_requested", Callable(self, "_on_structure_placement_requested"))
	game_state.connect("recycle_mode_requested", Callable(self, "_on_recycle_mode_requested"))
	game_state.connect("cancel_active_modes", Callable(self, "_on_cancel_active_modes"))

	print("[SM] Catalog loaded keys: ", Catalog.catalog.keys())

# ---- Requests from GameState ----

func _on_structure_placement_requested(data: Dictionary) -> void:
	var cost: Dictionary = data.get("cost", {})
	if not _can_afford(cost):
		print("[SM] Not enough resources to place structure")
		return
	var amount: int = int(data.get("amount", 1))
	base_grid.enter_place_mode(data, amount)

func _can_afford(cost: Dictionary) -> bool:
	for res in cost.keys():
		var needed: int = cost[res]
		if needed <= 0:
			continue
		var current: int = _get_resource_amount(res)
		if current < needed:
			return false
	return true

func _get_resource_amount(res: String) -> int:
	match res:
		"stone": return resources.stone_count
		"wood":  return resources.wood_count
		"food":  return resources.food_count
		"pop":   return resources.pop_count
		_:       return 0

func _on_recycle_mode_requested(data: Dictionary) -> void:
	var amount: int = int(data.get("amount", 1))
	base_grid.enter_remove_mode(amount)

func _on_cancel_active_modes() -> void:
	if base_grid:
		base_grid.clear_modes()
	if game_state and game_state.has_method("set_play_phase_state"):
		game_state.set_play_phase_state(game_state.PLAY_PHASE_STATE_IDLE)

# ---- Mode completion (from BaseGrid) ----

func _on_place_mode_completed() -> void:
	if game_state and game_state.has_method("set_play_phase_state"):
		game_state.set_play_phase_state(game_state.PLAY_PHASE_STATE_IDLE)

func _on_remove_mode_completed() -> void:
	if game_state and game_state.has_method("set_play_phase_state"):
		game_state.set_play_phase_state(game_state.PLAY_PHASE_STATE_IDLE)

# ---- Tile events (from BaseGrid) ----

func _on_tile_placed(tile_info: Dictionary) -> void:
	var layer_name: String = tile_info.get("layer", "")
	var source_name: String = tile_info.get("source_name", "")
	var tile_name: String = tile_info.get("tile_name", "")
	var pos: Vector2i = tile_info.get("pos", Vector2i.ZERO)

	print("\n[SM] tile_info received:")
	print("  layer:       ", layer_name)
	print("  source_name: ", source_name)
	print("  tile_name:   ", tile_name)
	print("  pos:         ", pos)
	print("  source_id:   ", tile_info.get("source_id", -1))
	print("  atlas_coords:", tile_info.get("atlas_coords", Vector2i(-1, -1)))

	print("[SM] Catalog layers: ", Catalog.catalog.keys())
	if Catalog.catalog.has(layer_name):
		print("[SM] Catalog sources in '%s': " % layer_name, Catalog.catalog[layer_name].keys())
	else:
		print("[SM] Layer '%s' not found in catalog" % layer_name)

	var source_data: Dictionary = Catalog.catalog.get(layer_name, {}).get(source_name, {})
	var spec: Variant = null  # StructureSpec if you attach one later

	if source_data.is_empty():
		print("[SM] ❌ Catalog lookup failed — no entry for layer='%s', source='%s'" % [layer_name, source_name])
		print("[SM] Placed '%s' at %s -> spec=NULL" % [tile_name, pos])
	else:
		var display_name: String = source_data.get("display_name", tile_name)
		print("[SM] ✅ Catalog lookup succeeded — placed '%s' from source '%s' at %s" % [display_name, source_name, pos])

	var inst: Dictionary = {
		"pos": pos,
		"spec": spec,
		"placed_at": _placed_counter
	}
	_placed_counter += 1
	_instances.append(inst)
	_by_pos[pos] = inst

	emit_signal("structure_placed", {"structure": spec, "tile": tile_info})

	if place_cost_on_success and resources and resources.has_method("add_stone"):
		resources.add_stone(-1)

func _on_tile_erased(tile_info: Dictionary) -> void:
	var pos: Vector2i = tile_info.get("pos", Vector2i.ZERO)
	if _by_pos.has(pos):
		var inst: Dictionary = _by_pos[pos]
		_instances.erase(inst)
		_by_pos.erase(pos)

	emit_signal("structure_recycled", tile_info)

	if resources and resources.has_method("add_stone"):
		resources.add_stone(1)

# ---- Tile effects phase (called by GameState) ----

func run_tile_effects_phase() -> void:
	if _instances.is_empty():
		emit_signal("tile_effects_done")
		return

	var ctx: EffectContext = EffectContext.new()
	ctx.game_state = game_state
	ctx.resources = resources
	ctx.base_grid = base_grid

	if base_grid and base_grid.structures_layer:
		ctx.structures_layer = base_grid.structures_layer
	else:
		ctx.structures_layer = base_grid.get_node("%StructuresLayer")

	_instances.sort_custom(Callable(self, "_cmp_instance"))

	for inst: Dictionary in _instances:
		if inst.has("spec") and inst.spec != null:
			print("Resolving", inst.spec.id, "at", inst.pos)
			inst.spec.apply(ctx, inst.pos)

	emit_signal("tile_effects_done")

func _cmp_instance(a: Dictionary, b: Dictionary) -> bool:
	var pa: int = 0
	if a.has("spec") and a.spec != null:
		pa = a.spec.priority
	var pb: int = 0
	if b.has("spec") and b.spec != null:
		pb = b.spec.priority

	if pa == pb:
		return a.placed_at < b.placed_at
	return pa < pb
