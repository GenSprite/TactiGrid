## AIController.gd
## Drives enemy units. Called by GameManager at the start of the AI turn.
## Strategy: each enemy moves toward the nearest player unit, then attacks if in range.

extends Node

var game_manager  : Node    = null
var grid_manager  : Node2D  = null

# Entry point – processes all enemy units one after the other (with a small delay)
func run_ai_turn(enemy_units: Array, player_units: Array) -> void:
	for enemy in enemy_units:
		if is_instance_valid(enemy):
			await _process_unit(enemy, player_units)
			await get_tree().create_timer(0.4).timeout   # small pause for readability

# Decide move + attack for a single enemy unit
func _process_unit(enemy: Node2D, player_units: Array) -> void:
	if player_units.is_empty():
		return

	var target : Node2D = _find_nearest(enemy, player_units)
	if target == null:
		return

	# --- Move phase ---
	var blocked: Array = _get_occupied_tiles(enemy)
	var reachable : Array = grid_manager.highlight_move_range(
		enemy.grid_pos, enemy.move_range, blocked
	)

	# Pick the reachable tile closest to target
	var best_tile : Vector2i = enemy.grid_pos
	var best_dist : int      = _manhattan(enemy.grid_pos, target.grid_pos)

	for tile in reachable:
		var d: int = _manhattan(tile, target.grid_pos)
		if d < best_dist:
			best_dist = d
			best_tile = tile

	if best_tile != enemy.grid_pos:
		_move_unit(enemy, best_tile)
		await get_tree().create_timer(0.25).timeout

	# --- Attack phase ---
	var dist_to_target: int = _manhattan(enemy.grid_pos, target.grid_pos)
	if dist_to_target <= enemy.attack_range:
		target.take_damage(enemy.attack_damage)
		_flash_attack(enemy)

	enemy.has_moved = true
	enemy.has_acted = true
	grid_manager.clear_highlights()

func _move_unit(unit: Node2D, dest: Vector2i) -> void:
	unit.grid_pos = dest
	unit.position = grid_manager.grid_to_world(dest)

func _find_nearest(enemy: Node2D, player_units: Array) -> Node2D:
	var nearest : Node2D = null
	var min_d   : int    = 99999
	for p in player_units:
		if is_instance_valid(p):
			var d: int = _manhattan(enemy.grid_pos, p.grid_pos)
			if d < min_d:
				min_d = d
				nearest = p
	return nearest

func _get_occupied_tiles(exclude: Node2D) -> Array:
	var tiles := []
	for unit in game_manager.all_units():
		if unit != exclude:
			tiles.append(unit.grid_pos)
	return tiles

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# Quick visual flash on the attacking unit
func _flash_attack(unit: Node2D) -> void:
	var rect : ColorRect = unit.get_node_or_null("SpriteRect")
	if rect:
		var orig: Color = rect.color
		rect.color = Color.WHITE
		await get_tree().create_timer(0.15).timeout
		rect.color = orig
