## AIController.gd
## Drives enemy units each AI turn.
## Strategy: move toward the nearest player unit, then attack if in range.

extends Node

var game_manager : Node   = null
var grid_manager : Node2D = null

# ------------------------------------------------------------------ #
#  Public entry point — called by GameManager                          #
# ------------------------------------------------------------------ #
func run_ai_turn(enemy_units: Array, player_units: Array) -> void:
	for enemy in enemy_units:
		if is_instance_valid(enemy) and not player_units.is_empty():
			await _process_unit(enemy, player_units)
			await get_tree().create_timer(0.35).timeout

# ------------------------------------------------------------------ #
#  Per-unit logic                                                      #
# ------------------------------------------------------------------ #
func _process_unit(enemy: Node2D, player_units: Array) -> void:
	var target : Node2D = _find_nearest(enemy, player_units)
	if target == null or not is_instance_valid(target):
		return

	# ── Move phase ──
	var blocked   : Array  = _get_occupied_tiles(enemy)
	var reachable : Array  = grid_manager.highlight_move_range(
		enemy.grid_pos, enemy.move_range, blocked
	)

	var best_tile : Vector2i = enemy.grid_pos
	var best_dist : int      = _manhattan(enemy.grid_pos, target.grid_pos)

	for tile in reachable:
		var d : int = _manhattan(tile, target.grid_pos)
		if d < best_dist:
			best_dist = d
			best_tile = tile

	if best_tile != enemy.grid_pos:
		await _tween_move(enemy, best_tile)

	# ── Attack phase ──
	# Re-evaluate target in case it died during a previous unit's attack
	if not is_instance_valid(target):
		target = _find_nearest(enemy, player_units)

	if target != null and is_instance_valid(target):
		var dist : int = _manhattan(enemy.grid_pos, target.grid_pos)
		if dist <= enemy.attack_range:
			target.take_damage(enemy.attack_damage)
			await _flash_attack(enemy)

	enemy.has_moved = true
	enemy.has_acted = true
	enemy._refresh_visuals()
	grid_manager.clear_highlights()

# ------------------------------------------------------------------ #
#  Movement with a Tween for smooth sliding                            #
# ------------------------------------------------------------------ #
func _tween_move(unit: Node2D, dest: Vector2i) -> void:
	unit.grid_pos = dest
	var world_dest : Vector2 = grid_manager.grid_to_world(dest)
	var tween : Tween = unit.create_tween()
	tween.tween_property(unit, "position", world_dest, 0.22).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

# ------------------------------------------------------------------ #
#  Helpers                                                             #
# ------------------------------------------------------------------ #
func _find_nearest(enemy: Node2D, player_units: Array) -> Node2D:
	var nearest : Node2D = null
	var min_d   : int    = 999999
	for p in player_units:
		if is_instance_valid(p):
			var d : int = _manhattan(enemy.grid_pos, p.grid_pos)
			if d < min_d:
				min_d = d
				nearest = p
	return nearest

func _get_occupied_tiles(exclude: Node2D) -> Array:
	var tiles : Array = []
	for unit in game_manager.all_units():
		if unit != exclude and is_instance_valid(unit):
			tiles.append(unit.grid_pos)
	return tiles

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _flash_attack(unit: Node2D) -> void:
	var rect : ColorRect = unit.get_node_or_null("SpriteRect")
	if rect:
		var orig  : Color = rect.color
		var tween : Tween = unit.create_tween()
		tween.tween_property(rect, "color", Color.WHITE,   0.08)
		tween.tween_property(rect, "color", orig,          0.14)
		await tween.finished
