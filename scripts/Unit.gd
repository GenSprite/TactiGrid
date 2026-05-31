## Unit.gd — with sprite sheet animation support

extends Node2D

# ── Exported Stats ────────────────────────────────────────────────────
@export var unit_name     : String    = "Unit"
@export var max_hp        : int       = 30
@export var move_range    : int       = 3
@export var attack_range  : int       = 1
@export var attack_damage : int       = 10
@export var is_player_unit: bool      = true
@export var unit_color    : Color     = Color(0.20, 0.60, 1.00)
@export var unit_texture  : Texture2D = null

# ── Sprite Sheet Layout — SET THESE TO MATCH YOUR SHEET ──────────────
@export var frame_width   : int = 48   # px per frame
@export var frame_height  : int = 48
@export var sheet_columns : int = 4    # how many columns in the sheet

# Maps animation name → [start_frame, frame_count, fps, loop]
@export var anim_config : Dictionary = {
	"idle":   [0,  4, 8,  true],
	"walk":   [4,  4, 10, true],
	"attack": [8,  3, 12, false],
	"die":    [11, 2, 6,  false],
}

# ── Runtime State ─────────────────────────────────────────────────────
var current_hp : int      = 0
var grid_pos   : Vector2i = Vector2i.ZERO
var has_moved  : bool     = false
var has_acted  : bool     = false

var grid_manager : Node2D = null
var game_manager : Node   = null

# ── Child references ──────────────────────────────────────────────────
@onready var sprite_rect : AnimatedSprite2D = $SpriteRect
@onready var hp_label    : Label            = $HPLabel

# ── Lifecycle ─────────────────────────────────────────────────────────
func _ready() -> void:
	current_hp = max_hp
	if sprite_rect and unit_texture:
		_build_sprite_frames()
	_refresh_visuals()

func place_on_grid(pos: Vector2i) -> void:
	grid_pos = pos
	position = grid_manager.grid_to_world(pos)

# ── Sprite Sheet Setup ────────────────────────────────────────────────
func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()

	for anim_name in anim_config:
		var cfg        : Array = anim_config[anim_name]
		var start      : int   = cfg[0]
		var count      : int   = cfg[1]
		var fps        : float = cfg[2]
		var should_loop: bool  = cfg[3]

		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, should_loop)

		for i in range(count):
			var frame_idx : int = start + i
			var col       : int = frame_idx % sheet_columns
			var row       : int = frame_idx / sheet_columns

			var atlas := AtlasTexture.new()
			atlas.atlas  = unit_texture
			atlas.region = Rect2(
				col * frame_width,
				row * frame_height,
				frame_width,
				frame_height
			)
			frames.add_frame(anim_name, atlas)

	sprite_rect.sprite_frames = frames
	sprite_rect.play("idle")

	# After non-looping animations finish, return to idle
	sprite_rect.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	var finished_anim : String = sprite_rect.animation
	if finished_anim in ["attack", "die"]:
		if current_hp > 0:
			play_anim("idle")

# ── Animation helpers ─────────────────────────────────────────────────
func play_anim(anim_name: String) -> void:
	if sprite_rect and sprite_rect.sprite_frames \
	   and sprite_rect.sprite_frames.has_animation(anim_name):
		sprite_rect.play(anim_name)

func play_move() -> void:
	play_anim("walk")

func play_attack() -> void:
	play_anim("attack")

func play_idle() -> void:
	play_anim("idle")

# ── Combat ────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	_refresh_visuals()
	if current_hp == 0:
		die()

func die() -> void:
	play_anim("die")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_unit_died(self)
	# Delay queue_free so the death animation can finish
	await sprite_rect.animation_finished
	queue_free()

# ── Turn helpers ──────────────────────────────────────────────────────
func reset_turn() -> void:
	has_moved = false
	has_acted = false
	play_idle()
	_refresh_visuals()

func is_done() -> bool:
	return has_moved and has_acted

# ── Visuals ───────────────────────────────────────────────────────────
func _refresh_visuals() -> void:
	if sprite_rect:
		sprite_rect.modulate = Color.WHITE if current_hp > 0 else Color(0.4, 0.4, 0.4)
	if hp_label:
		hp_label.text = "%d/%d" % [current_hp, max_hp]
