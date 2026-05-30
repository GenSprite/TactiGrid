## GridManager.gd
## Manages the grid: tile states, highlighting, and coordinate conversions.
## Attach to a Node2D called "GridManager" in your main scene.

extends Node2D

const TILE_SIZE := 64          # pixels per tile
const GRID_COLS := 10
const GRID_ROWS := 8

# Tile state flags
enum TileState { NORMAL, MOVE_RANGE, ATTACK_RANGE, SELECTED }

var tile_states := {}           # Vector2i -> TileState
var tile_colors := {
	TileState.NORMAL:       Color(0.20, 0.22, 0.28, 1.0),
	TileState.MOVE_RANGE:   Color(0.25, 0.55, 0.90, 0.55),
	TileState.ATTACK_RANGE: Color(0.90, 0.30, 0.30, 0.55),
	TileState.SELECTED:     Color(1.00, 0.85, 0.20, 0.80),
}

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	for row in GRID_ROWS:
		for col in GRID_COLS:
			tile_states[Vector2i(col, row)] = TileState.NORMAL

# Convert grid coordinates to world position (centre of tile)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2,
				   grid_pos.y * TILE_SIZE + TILE_SIZE / 2)

# Convert world position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func is_valid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_COLS \
		and grid_pos.y >= 0 and grid_pos.y < GRID_ROWS

# Highlight all tiles reachable within move_range steps (BFS, ignores enemies)
func highlight_move_range(origin: Vector2i, move_range: int, blocked: Array) -> Array:
	clear_highlights()
	var reachable: Array = []
	var visited := {origin: 0}
	var queue := [origin]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var steps: int = visited[current]
		if steps == 0 and current != origin:
			pass  # origin itself never highlighted as move target
		if current != origin:
			tile_states[current] = TileState.MOVE_RANGE
			reachable.append(current)
		if steps < move_range:
			for neighbor in get_neighbors(current):
				if neighbor not in visited and neighbor not in blocked:
					visited[neighbor] = steps + 1
					queue.append(neighbor)

	queue_redraw()
	return reachable

# Highlight all tiles within attack_range (Manhattan distance ring)
func highlight_attack_range(origin: Vector2i, attack_range: int, move_tiles: Array) -> void:
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var pos := Vector2i(col, row)
			var dist: int = abs(pos.x - origin.x) + abs(pos.y - origin.y)
			if dist <= attack_range and dist > 0 and pos not in move_tiles:
				tile_states[pos] = TileState.ATTACK_RANGE
	queue_redraw()

func highlight_selected(grid_pos: Vector2i) -> void:
	tile_states[grid_pos] = TileState.SELECTED
	queue_redraw()

func clear_highlights() -> void:
	for key in tile_states:
		tile_states[key] = TileState.NORMAL
	queue_redraw()

func get_neighbors(pos: Vector2i) -> Array:
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var result := []
	for d in dirs:
		var n: Vector2i = pos + d
		if is_valid(n):
			result.append(n)
	return result

# Draw grid tiles
func _draw() -> void:
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var pos: Vector2i = Vector2i(col, row)
			var state: int = tile_states.get(pos, TileState.NORMAL)
			var rect: Rect2 = Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			draw_rect(rect, tile_colors[state])
			draw_rect(rect, Color(0.5, 0.5, 0.6, 0.4), false, 1.0)   # border
