## Unit.gd
## Base class for all player and AI units.
## Attach to a Node2D with a ColorRect child (for the unit sprite placeholder).

extends Node2D

# ---------- Unit Stats ----------
@export var unit_name      : String = "Unit"
@export var max_hp         : int    = 30
@export var move_range     : int    = 3
@export var attack_range   : int    = 1
@export var attack_damage  : int    = 10
@export var is_player_unit : bool   = true
@export var unit_color     : Color  = Color(0.2, 0.6, 1.0)  # blue = player

# ---------- Runtime State ----------
var current_hp  : int
var grid_pos    : Vector2i
var has_moved   : bool = false
var has_acted   : bool = false

# References (set by GameManager after instantiation)
var grid_manager  : Node2D   = null
var game_manager  : Node     = null

# ---------- Child references (set in _ready) ----------
@onready var sprite_rect : ColorRect = $SpriteRect
@onready var hp_label    : Label     = $HPLabel

func _ready() -> void:
	current_hp = max_hp
	_refresh_visuals()

# Call this after placing the unit on the grid
func place_on_grid(pos: Vector2i) -> void:
	grid_pos = pos
	position = grid_manager.grid_to_world(pos)

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	_refresh_visuals()
	if current_hp == 0:
		die()

func die() -> void:
	game_manager.on_unit_died(self)
	queue_free()

func reset_turn() -> void:
	has_moved = false
	has_acted = false
	_refresh_visuals()

func is_done() -> bool:
	return has_moved and has_acted

func _refresh_visuals() -> void:
	if sprite_rect:
		sprite_rect.color = unit_color if current_hp > 0 else Color(0.4, 0.4, 0.4)
	if hp_label:
		hp_label.text = "%d/%d" % [current_hp, max_hp]
