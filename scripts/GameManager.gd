## GameManager.gd
## Central controller: turn flow, input handling, unit spawning, win/lose detection.

extends Node

enum Phase { PLAYER_TURN, AI_TURN, GAME_OVER }

var phase         : Phase  = Phase.PLAYER_TURN
var selected_unit : Node2D = null
var move_tiles    : Array  = []   # blue-highlighted tiles for the selected unit
var attack_tiles  : Array  = []   # red-highlighted tiles for the selected unit

var player_units  : Array  = []
var enemy_units   : Array  = []

@onready var grid_manager  : Node2D = $"../GridManager"
@onready var ai_controller : Node   = $AIController
@onready var ui_manager    : Node   = $UIManager

# ------------------------------------------------------------------ #
#  Ready                                                               #
# ------------------------------------------------------------------ #
func _ready() -> void:
	ai_controller.game_manager = self
	ai_controller.grid_manager = grid_manager
	ui_manager.game_manager    = self
	_spawn_units()
	ui_manager.set_turn_label("Player Turn")

# ------------------------------------------------------------------ #
#  Unit Spawning                                                       #
# ------------------------------------------------------------------ #
func _spawn_units() -> void:
	var player_data : Array = [
		{
			pos=Vector2i(1,2), unit_name="Soldier", hp=30, mv=3, atk=1, dmg=10,
			color=Color(0.20, 0.60, 1.00),
			texture=preload("res://assets/sprites/Pawn/Blue/Pawn_Blue.png")
		},
		{
			pos=Vector2i(1,4), unit_name="Archer", hp=20, mv=2, atk=2, dmg=8,
			color=Color(0.30, 0.90, 0.40),
			texture=preload("res://assets/sprites/Archer/Blue/Archer_Blue.png")
		},
		{
			pos=Vector2i(1,6), unit_name="Knight", hp=50, mv=2, atk=1, dmg=15,
			color=Color(0.874, 0.718, 0.967, 1.0),
			texture=preload("res://assets/sprites/Warrior/Blue/Warrior_Blue.png")
		},
	]
	for d in player_data:
		player_units.append(_create_unit(d, true))

	# FIX 1: enemy entries now include texture and color keys,
	# matching the structure _create_unit expects.
	var enemy_data : Array = [
		{
			pos=Vector2i(8,2), unit_name="Grunt",  hp=25, mv=3, atk=1, dmg=8,
			color=Color(1.00, 0.30, 0.30),
			texture=preload("res://assets/sprites/Pawn/Red/Pawn_Red.png")
		},
		{
			pos=Vector2i(8,4), unit_name="Brute",  hp=40, mv=2, atk=1, dmg=12,
			color=Color(0.90, 0.20, 0.20),
			texture=preload("res://assets/sprites/Warrior/Red/Warrior_Red.png")
		},
		{
			pos=Vector2i(8,6), unit_name="Sniper", hp=20, mv=2, atk=3, dmg=10,
			color=Color(0.80, 0.10, 0.40),
			texture=preload("res://assets/sprites/Archer/Red/Archer_Red.png")
		},
	]
	for d in enemy_data:
		enemy_units.append(_create_unit(d, false))

func _create_unit(data: Dictionary, is_player: bool) -> Node2D:
	var unit_scene : PackedScene = preload("res://scenes/Unit.tscn")
	var u : Node2D = unit_scene.instantiate()
	u.unit_name      = data.unit_name
	# FIX 2: use data.get() so a missing key returns null instead of crashing.
	u.unit_texture   = data.get("texture", null)
	# FIX 3: unit_color was never assigned; missing it breaks the hit-flash tween
	# (enemies would flash back to the default blue instead of their own colour).
	u.unit_color     = data.get("color", Color.WHITE)
	u.max_hp         = data.hp
	u.move_range     = data.mv
	u.attack_range   = data.atk
	u.attack_damage  = data.dmg
	u.is_player_unit = is_player
	u.grid_manager   = grid_manager
	u.game_manager   = self
	add_child(u)
	u.place_on_grid(data.pos)
	return u

# ------------------------------------------------------------------ #
#  Input Handling                                                      #
# ------------------------------------------------------------------ #
func _input(event: InputEvent) -> void:
	if phase != Phase.PLAYER_TURN:
		return
	if not (event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed):
		return

	var clicked : Vector2i = grid_manager.get_mouse_grid_pos()
	if not grid_manager.is_valid(clicked):
		return

	# Mark the event handled so UI buttons don't double-fire
	get_viewport().set_input_as_handled()
	_handle_player_click(clicked)

func _handle_player_click(clicked: Vector2i) -> void:
	if selected_unit != null:

		# --- Try to MOVE ---
		if clicked in move_tiles and not selected_unit.has_moved:
			_move_selected_unit(clicked)
			return

		# --- Try to ATTACK ---
		if clicked in attack_tiles and not selected_unit.has_acted:
			var target : Node2D = _unit_at(clicked, false)
			if target != null:
				_attack(selected_unit, target)
				return

		# --- Switch to another friendly ---
		var friendly : Node2D = _unit_at(clicked, true)
		if friendly != null and friendly != selected_unit:
			_select_unit(friendly)
			return

		# --- Click on the already-selected unit: keep selected (do nothing) ---
		if clicked == selected_unit.grid_pos:
			return

		# --- Anything else: deselect ---
		_deselect()
		return

	# Nothing selected — try picking a friendly
	var friendly : Node2D = _unit_at(clicked, true)
	if friendly != null:
		_select_unit(friendly)

# ------------------------------------------------------------------ #
#  Selection                                                           #
# ------------------------------------------------------------------ #
func _select_unit(unit: Node2D) -> void:
	grid_manager.clear_highlights()
	ui_manager.clear_unit_info()

	selected_unit = unit
	move_tiles    = []
	attack_tiles  = []

	# Yellow tile for the unit itself
	grid_manager.highlight_selected(unit.grid_pos)

	# Blue move tiles
	if not unit.has_moved:
		var blocked : Array = _occupied_tiles_except(unit)
		move_tiles = grid_manager.highlight_move_range(
			unit.grid_pos, unit.move_range, blocked
		)

	# Red attack tiles
	if not unit.has_acted:
		grid_manager.highlight_attack_range(
			unit.grid_pos, unit.attack_range, move_tiles
		)
		attack_tiles = _collect_attack_tiles(unit.grid_pos, unit.attack_range, move_tiles)

	ui_manager.show_unit_info(unit)

func _deselect() -> void:
	selected_unit = null
	move_tiles    = []
	attack_tiles  = []
	grid_manager.clear_highlights()
	ui_manager.clear_unit_info()

# ------------------------------------------------------------------ #
#  Move / Attack                                                       #
# ------------------------------------------------------------------ #
func _move_selected_unit(dest: Vector2i) -> void:
	selected_unit.play_move() 
	selected_unit.grid_pos  = dest
	selected_unit.position  = grid_manager.grid_to_world(dest)
	selected_unit.has_moved = true
	selected_unit._refresh_visuals()

	grid_manager.clear_highlights()
	move_tiles   = []
	attack_tiles = []

	grid_manager.highlight_selected(selected_unit.grid_pos)

	if not selected_unit.has_acted:
		grid_manager.highlight_attack_range(
			selected_unit.grid_pos, selected_unit.attack_range, []
		)
		attack_tiles = _collect_attack_tiles(
			selected_unit.grid_pos, selected_unit.attack_range, []
		)

	_check_end_player_turn()

func _attack(attacker: Node2D, target: Node2D) -> void:
	attacker.play_attack() 
	target.take_damage(attacker.attack_damage)
	attacker.has_acted = true
	attacker.has_moved = true
	_deselect()
	_check_end_player_turn()

# ------------------------------------------------------------------ #
#  Turn Management                                                     #
# ------------------------------------------------------------------ #
func _check_end_player_turn() -> void:
	if phase == Phase.GAME_OVER:
		return
	for u in player_units:
		if is_instance_valid(u) and not u.is_done():
			return
	_start_ai_turn()

func end_player_turn() -> void:
	if phase != Phase.PLAYER_TURN:
		return
	_deselect()
	_start_ai_turn()

func _start_ai_turn() -> void:
	phase = Phase.AI_TURN
	ui_manager.set_turn_label("Enemy Turn")
	await ai_controller.run_ai_turn(enemy_units, player_units)
	if phase != Phase.GAME_OVER:
		_start_player_turn()

func _start_player_turn() -> void:
	for u in player_units:
		if is_instance_valid(u):
			u.reset_turn()
	phase = Phase.PLAYER_TURN
	ui_manager.set_turn_label("Player Turn")

# ------------------------------------------------------------------ #
#  Win / Lose                                                          #
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
	grid_manager.clear_highlights()
	ui_manager.show_game_over(player_wins)

func restart_game() -> void:
	get_tree().reload_current_scene()

# ------------------------------------------------------------------ #
#  Helpers                                                             #
# ------------------------------------------------------------------ #
func all_units() -> Array:
	return player_units + enemy_units

func _unit_at(grid_pos: Vector2i, is_player: bool) -> Node2D:
	var pool : Array = player_units if is_player else enemy_units
	for u in pool:
		if is_instance_valid(u) and u.grid_pos == grid_pos:
			return u
	return null

func _occupied_tiles_except(exclude: Node2D) -> Array:
	var tiles : Array = []
	for u in all_units():
		if u != exclude and is_instance_valid(u):
			tiles.append(u.grid_pos)
	return tiles

func _collect_attack_tiles(origin: Vector2i, attack_range: int, exclude_tiles: Array) -> Array:
	var result : Array = []
	for row in grid_manager.GRID_ROWS:
		for col in grid_manager.GRID_COLS:
			var pos  : Vector2i = Vector2i(col, row)
			var dist : int      = abs(pos.x - origin.x) + abs(pos.y - origin.y)
			if dist <= attack_range and dist > 0 and pos not in exclude_tiles:
				result.append(pos)
	return result

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
