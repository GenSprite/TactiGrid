## GameManager.gd
## Central controller: turn flow, input handling, win/lose detection.
## Attach to an Autoload or the root Node of your main scene.

extends Node

# ---- Turn states ----
enum Phase { PLAYER_TURN, AI_TURN, GAME_OVER }

var phase            : Phase    = Phase.PLAYER_TURN
var selected_unit    : Node2D   = null
var move_tiles       : Array    = []   # highlighted move positions

var player_units     : Array    = []
var enemy_units      : Array    = []

@onready var grid_manager  : Node2D = $"../GridManager"
@onready var ai_controller : Node   = $AIController
@onready var ui_manager    : Node   = $UIManager

func _ready() -> void:
	ai_controller.game_manager  = self
	ai_controller.grid_manager  = grid_manager
	_spawn_units()
	ui_manager.set_turn_label("Player Turn")

# ------------------------------------------------------------------ #
#  Unit Spawning                                                       #
# ------------------------------------------------------------------ #
func _spawn_units() -> void:
	# Player units (left side)
	var player_data: Array = [
		{pos=Vector2i(1,2), name="Soldier",  hp=30, mv=3, atk=1, dmg=10, color=Color(0.2,0.6,1.0)},
		{pos=Vector2i(1,4), name="Archer",   hp=20, mv=2, atk=2, dmg=8,  color=Color(0.3,0.9,0.4)},
		{pos=Vector2i(1,6), name="Knight",   hp=50, mv=2, atk=1, dmg=15, color=Color(0.9,0.8,0.2)},
	]
	for d in player_data:
		var u: Node2D = _create_unit(d, true)
		player_units.append(u)

	# Enemy units (right side)
	var enemy_data: Array = [
		{pos=Vector2i(8,2), name="Grunt",    hp=25, mv=3, atk=1, dmg=8,  color=Color(1.0,0.3,0.3)},
		{pos=Vector2i(8,4), name="Brute",    hp=40, mv=2, atk=1, dmg=12, color=Color(0.9,0.2,0.2)},
		{pos=Vector2i(8,6), name="Sniper",   hp=20, mv=2, atk=3, dmg=10, color=Color(0.8,0.1,0.4)},
	]
	for d in enemy_data:
		var u: Node2D = _create_unit(d, false)
		enemy_units.append(u)

func _create_unit(data: Dictionary, is_player: bool) -> Node2D:
	var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")
	var u : Node2D = unit_scene.instantiate()
	u.unit_name      = data.name
	u.max_hp         = data.hp
	u.move_range     = data.mv
	u.attack_range   = data.atk
	u.attack_damage  = data.dmg
	u.unit_color     = data.color
	u.is_player_unit = is_player
	u.grid_manager   = grid_manager
	u.game_manager   = self
	add_child(u)
	u.place_on_grid(data.pos)
	return u

# ------------------------------------------------------------------ #
#  Input Handling (Player Turn only)                                   #
# ------------------------------------------------------------------ #
func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.PLAYER_TURN:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_grid: Vector2i = grid_manager.world_to_grid(grid_manager.get_global_mouse_position())
		if not grid_manager.is_valid(clicked_grid):
			return
		_handle_player_click(clicked_grid)

func _handle_player_click(clicked: Vector2i) -> void:
	# Case 1: a friendly unit is already selected
	if selected_unit != null:
		# Sub-case A: clicked a move tile → move there
		if clicked in move_tiles and not selected_unit.has_moved:
			_move_selected_unit(clicked)
			return
		# Sub-case B: clicked an enemy in attack range → attack
		var enemy: Node2D = _unit_at(clicked, false)
		if enemy != null and not selected_unit.has_acted:
			var dist: int = abs(clicked.x - selected_unit.grid_pos.x) \
					  + abs(clicked.y - selected_unit.grid_pos.y)
			if dist <= selected_unit.attack_range:
				_attack(selected_unit, enemy)
				return
		# Sub-case C: clicked another friendly unit → select it instead
		var friendly: Node2D = _unit_at(clicked, true)
		if friendly != null:
			_select_unit(friendly)
			return
		# Sub-case D: clicked empty tile → deselect
		_deselect()
		return

	# Case 2: nothing selected – try to pick a friendly unit
	var friendly: Node2D = _unit_at(clicked, true)
	if friendly != null:
		_select_unit(friendly)

func _select_unit(unit: Node2D) -> void:
	_deselect()
	selected_unit = unit
	grid_manager.highlight_selected(unit.grid_pos)

	if not unit.has_moved:
		var blocked: Array = _occupied_tiles_except(unit)
		move_tiles = grid_manager.highlight_move_range(unit.grid_pos, unit.move_range, blocked)
	if not unit.has_acted:
		grid_manager.highlight_attack_range(unit.grid_pos, unit.attack_range, move_tiles)

	ui_manager.show_unit_info(unit)

func _deselect() -> void:
	selected_unit = null
	move_tiles    = []
	grid_manager.clear_highlights()
	ui_manager.clear_unit_info()

func _move_selected_unit(dest: Vector2i) -> void:
	selected_unit.grid_pos = dest
	selected_unit.position = grid_manager.grid_to_world(dest)
	selected_unit.has_moved = true
	# Re-highlight to show remaining actions
	grid_manager.clear_highlights()
	grid_manager.highlight_selected(selected_unit.grid_pos)
	if not selected_unit.has_acted:
		grid_manager.highlight_attack_range(
			selected_unit.grid_pos, selected_unit.attack_range, []
		)
	_check_end_player_turn()

func _attack(attacker: Node2D, target: Node2D) -> void:
	target.take_damage(attacker.attack_damage)
	attacker.has_acted = true
	attacker.has_moved = true   # attacking ends movement too
	_deselect()
	_check_end_player_turn()

# ------------------------------------------------------------------ #
#  Turn Management                                                     #
# ------------------------------------------------------------------ #
func _check_end_player_turn() -> void:
	var all_done: bool = true
	for u in player_units:
		if is_instance_valid(u) and not u.is_done():
			all_done = false
			break
	if all_done:
		_start_ai_turn()

# Called by "End Turn" button in the UI
func end_player_turn() -> void:
	_deselect()
	_start_ai_turn()

func _start_ai_turn() -> void:
	phase = Phase.AI_TURN
	ui_manager.set_turn_label("Enemy Turn")
	await ai_controller.run_ai_turn(enemy_units, player_units)
	_start_player_turn()

func _start_player_turn() -> void:
	for u in player_units:
		if is_instance_valid(u):
			u.reset_turn()
	phase = Phase.PLAYER_TURN
	ui_manager.set_turn_label("Player Turn")

# ------------------------------------------------------------------ #
#  Win / Lose Detection                                                #
# ------------------------------------------------------------------ #
func on_unit_died(unit: Node2D) -> void:
	if unit.is_player_unit:
		player_units.erase(unit)
		if player_units.is_empty():
			_game_over(false)
	else:
		enemy_units.erase(unit)
		if enemy_units.is_empty():
			_game_over(true)

func _game_over(player_wins: bool) -> void:
	phase = Phase.GAME_OVER
	ui_manager.show_game_over(player_wins)

# ------------------------------------------------------------------ #
#  Helpers                                                             #
# ------------------------------------------------------------------ #
func all_units() -> Array:
	return player_units + enemy_units

func _unit_at(grid_pos: Vector2i, is_player: bool) -> Node2D:
	var pool: Array = player_units if is_player else enemy_units
	for u in pool:
		if is_instance_valid(u) and u.grid_pos == grid_pos:
			return u
	return null

func _occupied_tiles_except(exclude: Node2D) -> Array:
	var tiles: Array = []
	for u in all_units():
		if u != exclude and is_instance_valid(u):
			tiles.append(u.grid_pos)
	return tiles
