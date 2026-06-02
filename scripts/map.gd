extends Node2D

const GRID_SIZE = 8
const TILE_SIZE = 128



# Terrain types
enum Tile {
	GRASS,
	WATER,
	ELEVATED,
	BRIDGE
}

# 8x8 grid layout — 0=Grass, 1=Water, 2=Elevated, 3=Bridge
var grid_layout = [
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 2, 1, 1, 2, 0, 0],
	[0, 0, 2, 3, 3, 2, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
]

const UnitScene = preload("res://scenes/unit.tscn")

func _ready():
	generate_map()

	spawn_unit("warrior", Vector2i(1, 1))
	spawn_unit("archer", Vector2i(2, 1))
	spawn_unit("lancer", Vector2i(3, 1))

func spawn_unit(type: String, pos: Vector2i):
	var unit = UnitScene.instantiate()

	unit.unit_type = type
	unit.grid_pos = pos

	print("Spawning:", type, " at ", pos)

	$Units.add_child(unit)

func generate_map():
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var tile_type = grid_layout[row][col]
			place_tile(row, col, tile_type)

func place_tile(row: int, col: int, tile_type: int):
	var pos = Vector2(col * TILE_SIZE, row * TILE_SIZE)
	# You'll assign atlas coords based on your TileSet here
	pass

# Convert grid coords to world position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

# Convert world position to grid coords
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)

# Check if a grid position is valid and walkable
func is_walkable(grid_pos: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= GRID_SIZE:
		return false
	if grid_pos.y < 0 or grid_pos.y >= GRID_SIZE:
		return false
	var tile = grid_layout[grid_pos.y][grid_pos.x]
	return tile != Tile.WATER  # Water blocks movement
