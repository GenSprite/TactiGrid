## Unit.gd
## Base class for all player and AI units.
## Attach to a Node2D called "Unit" (scenes/Unit.tscn).

extends Node2D

# ------------------------------------------------------------------ #
#  Exported Stats  (editable per-instance in Godot Inspector)          #
# ------------------------------------------------------------------ #
@export var unit_name     : String = "Unit"
@export var max_hp        : int    = 30
@export var move_range    : int    = 3
@export var attack_range  : int    = 1
@export var attack_damage : int    = 10
@export var is_player_unit: bool   = true
@export var unit_color    : Color  = Color(0.20, 0.60, 1.00)
@export var unit_texture : Texture2D = null  

# ------------------------------------------------------------------ #
#  Runtime State                                                       #
# ------------------------------------------------------------------ #
var current_hp : int       = 0
var grid_pos   : Vector2i  = Vector2i.ZERO
var has_moved  : bool      = false
var has_acted  : bool      = false

# Set by GameManager after instantiation
var grid_manager : Node2D = null
var game_manager : Node   = null

# ------------------------------------------------------------------ #
#  Child references                                                    #
# ------------------------------------------------------------------ #
@onready var sprite_rect : Sprite2D = $SpriteRect
@onready var hp_label    : Label     = $HPLabel

# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #
func _ready() -> void:
	current_hp = max_hp
	if sprite_rect and unit_texture:
		sprite_rect.texture = unit_texture
	_refresh_visuals()

## Place this unit at a grid tile and snap position.
func place_on_grid(pos: Vector2i) -> void:
	grid_pos = pos
	position = grid_manager.grid_to_world(pos)

# ------------------------------------------------------------------ #
#  Combat                                                              #
# ------------------------------------------------------------------ #
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	_refresh_visuals()
	_play_hit_flash()
	if current_hp == 0:
		die()

func die() -> void:
	# Notify manager first so it can remove from lists before queue_free
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_unit_died(self)
	queue_free()

# ------------------------------------------------------------------ #
#  Turn helpers                                                        #
# ------------------------------------------------------------------ #
func reset_turn() -> void:
	has_moved = false
	has_acted = false
	_refresh_visuals()

func is_done() -> bool:
	return has_moved and has_acted

# ------------------------------------------------------------------ #
#  Visuals                                                             #
# ------------------------------------------------------------------ #
func _refresh_visuals() -> void:
	if sprite_rect:
		sprite_rect.modulate = Color.WHITE if current_hp > 0 else Color(0.4, 0.4, 0.4)
	if hp_label:
		hp_label.text = "%d/%d" % [current_hp, max_hp]

func _play_hit_flash() -> void:
	if not sprite_rect:
		return
	var tween : Tween = create_tween()
	tween.tween_property(sprite_rect, "color", Color.WHITE, 0.07)
	tween.tween_property(sprite_rect, "color", unit_color, 0.12)
