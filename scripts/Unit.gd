extends CharacterBody2D

# --- Unit Identity ---
@export var unit_name: String = "Unit"
@export var team: String = "blue"
@export var unit_type: String = "warrior"  # "warrior", "archer", "lancer"

# --- Stats ---
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var move_range: int = 3
@export var attack_range: int = 1
@export var attack_damage: int = 25

# --- Grid Position ---
var grid_pos: Vector2i = Vector2i(0, 0)

# --- State ---
var has_moved: bool = false
var has_attacked: bool = false
var is_alive: bool = true
var facing: String = "right"  # "right", "up", "down"

# --- Node References ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar

const TILE_SIZE = 128

func _ready():
	print("UNIT READY")

	apply_unit_stats()
	setup_animations()

	health_bar.max_value = max_hp
	health_bar.value = current_hp

	position = Vector2(
	grid_pos.x * TILE_SIZE + TILE_SIZE / 2,
	grid_pos.y * TILE_SIZE + TILE_SIZE / 2
)



# -------------------------------------------------------
# ANIMATION SETUP
# -------------------------------------------------------

func setup_animations():
	var frames = SpriteFrames.new()
	anim_sprite.sprite_frames = frames

	match unit_type:
		"warrior":
			_setup_warrior(frames)
		"archer":
			_setup_archer(frames)
		"lancer":
			_setup_lancer(frames)

	# Dead animation is shared across all units
	_add_dead_animation(frames)

# --- WARRIOR ---
# Spritesheet: 192x192, 6 cols x 8 rows, frame size = 32x24
# Row layout (adjust row indices to match your actual sheet):
# Row 0: idle, Row 1: walk, Row 2: attack_right
# Row 3: attack_up, Row 4: attack_down, Row 5: dead (if any)
func _setup_warrior(frames: SpriteFrames):
	var tex = load("res://assets/Warrior/%s/Warrior_%s.png" % [team.capitalize(), team.capitalize()])
	if tex == null:
		print("ERROR: Warrior texture not found")
		return

	var fw = 192
	var fh = 192  # frame height (192 / 8)

	# idle — row 0, all 6 frames
	_add_animation_from_row(frames, "idle", tex, 0, 6, fw, fh, true, 6.0)
	# walk — row 1, all 6 frames
	_add_animation_from_row(frames, "walk", tex, 0, 6, fw, fh, true, 12.0)
	# attack_right — row 2, all 6 frames
	_add_animation_from_row(frames, "attack_right", tex, 2, 6, fw, fh, false, 10.0)
	# attack_up — row 3, all 6 frames
	_add_animation_from_row(frames, "attack_up", tex, 6, 6, fw, fh, false, 10.0)
	# attack_down — row 4, all 6 frames
	_add_animation_from_row(frames, "attack_down", tex, 4, 6, fw, fh, false, 10.0)
	print("Warrior idle frames:",
	anim_sprite.sprite_frames.get_frame_count("idle"))
# --- ARCHER ---

# Spritesheet: 192x192, 8 cols x 7 rows, frame size = 24x27
# Row layout:
# Row 0: idle, Row 1: walk, Row 2: attack_right
# Row 3: attack_up, Row 4: attack_down
	print("Setting up archer")
func _setup_archer(frames: SpriteFrames):
	var tex = load("res://assets/Archer/%s/Archer_%s.png" % [team.capitalize(), team.capitalize()])
	if tex == null:
		print("ERROR: Archer texture not found")
		return

	var fw = 192
	var fh = 192# frame height (192 / 7)

	_add_animation_from_row(frames, "idle", tex, 0, 6, fw, fh, true, 6.0)
	_add_animation_from_row(frames, "walk", tex, 0, 6, fw, fh, true, 12.0)
	_add_animation_from_row(frames, "attack_right", tex, 3, 8, fw, fh, false, 10.0)
	_add_animation_from_row(frames, "attack_up", tex, 2, 8, fw, fh, false, 10.0)
	_add_animation_from_row(frames, "attack_down", tex, 6, 8, fw, fh, false, 10.0)

# --- LANCER ---
# Separate PNG per animation, all 1 row
# Idle:    320x320, 12 frames → frame = ~26x320 (full height)
# Run:     320x320,  6 frames → frame = ~53x320
# Attacks: 320x320,  3 frames → frame = ~106x320
	print("Setting up lancer")
func _setup_lancer(frames: SpriteFrames):
	# Idle
	_add_animation_from_separate(
		frames, "idle",
		"res://assets/lancer/Lancer_Idle.png",
		12, 1, true, 8.0
	)
	# Walk
	_add_animation_from_separate(
		frames, "walk",
		"res://assets/lancer/Lancer_Run.png",
		6, 1, true, 8.0
	)
	# Attack Right
	_add_animation_from_separate(
		frames, "attack_right",
		"res://assets/lancer/Lancer_Right_Attack.png",
		3, 1, false, 10.0
	)
	# Attack Up
	_add_animation_from_separate(
		frames, "attack_up",
		"res://assets/lancer/Lancer_Up_Attack.png",
		3, 1, false, 10.0
	)
	# Attack Down
	_add_animation_from_separate(
		frames, "attack_down",
		"res://assets/lancer/Lancer_Down_Attack.png",
		3, 1, false, 10.0
	)

# --- DEAD (shared) ---
func _add_dead_animation(frames: SpriteFrames):
	var tex = load("res://assets/Dead/Dead.png")
	if tex == null:
		print("ERROR: Dead texture not found")
		return
	frames.add_animation("dead")
	frames.set_animation_loop("dead", false)
	frames.set_animation_speed("dead", 5.0)
	frames.add_frame("dead", tex, 1.0)

# -------------------------------------------------------
# HELPERS — slice frames from spritesheets
# -------------------------------------------------------

# For Warrior/Archer: one big spritesheet, slice by row
func _add_animation_from_row(
	frames: SpriteFrames,
	anim_name: String,
	tex: Texture2D,
	row: int,
	col_count: int,
	frame_w: int,
	frame_h: int,
	loop: bool,
	speed: float
):
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)

	for col in col_count:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		frames.add_frame(anim_name, atlas, 1.0)

# For Lancer: separate PNG per animation, slice horizontally
func _add_animation_from_separate(
	frames: SpriteFrames,
	anim_name: String,
	path: String,
	col_count: int,
	row_count: int,
	loop: bool,
	speed: float
):
	if not ResourceLoader.exists(path):
		print("ERROR: Missing lancer texture: ", path)
		return

	var tex = load(path)
	var frame_w = int(tex.get_width() / col_count)
	var frame_h = int(tex.get_height() / row_count)

	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)

	for col in col_count:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * frame_w, 0, frame_w, frame_h)
		frames.add_frame(anim_name, atlas, 1.0)

# -------------------------------------------------------
# PLAY ANIMATIONS
# -------------------------------------------------------

func play_animation(anim_key: String):
	print("Trying to play:", anim_key)

	var anim_name: String
	match anim_key:
		"idle":
			anim_name = "idle"
		"walk":
			anim_name = "walk"
		"attack":
			anim_name = "attack_%s" % facing
		"dead":
			anim_name = "dead"
		_:
			anim_name = anim_key

	print("Animation resolved to:", anim_name)

	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		print("Playing:", anim_name)
		anim_sprite.play(anim_name)
	else:
		print("Animation not found:", anim_name)

# -------------------------------------------------------
# FACING (based on target position)
# -------------------------------------------------------

func update_facing(target_grid_pos: Vector2i):
	var diff = target_grid_pos - grid_pos
	if diff.y < 0:
		facing = "up"
	elif diff.y > 0:
		facing = "down"
	else:
		facing = "right"

# -------------------------------------------------------
# STATS
# -------------------------------------------------------

func apply_unit_stats():
	match unit_type:
		"warrior":
			max_hp = 120
			move_range = 3
			attack_range = 1
			attack_damage = 35
		"archer":
			max_hp = 80
			move_range = 3
			attack_range = 3
			attack_damage = 25
		"lancer":
			max_hp = 100
			move_range = 2
			attack_range = 2
			attack_damage = 30
	current_hp = max_hp

# -------------------------------------------------------
# MOVEMENT
# -------------------------------------------------------

func move_to(new_grid_pos: Vector2i):
	play_animation("walk")
	grid_pos = new_grid_pos
	position = Vector2(
	grid_pos.x * TILE_SIZE + TILE_SIZE / 2,
	grid_pos.y * TILE_SIZE + TILE_SIZE / 2
)
	has_moved = true
	play_animation("idle")

# -------------------------------------------------------
# COMBAT
# -------------------------------------------------------

func attack_target(target):
	update_facing(target.grid_pos)
	play_animation("attack")
	await anim_sprite.animation_finished
	target.take_damage(attack_damage)
	has_attacked = true
	play_animation("idle")

func take_damage(amount: int):
	current_hp -= amount
	current_hp = max(current_hp, 0)
	health_bar.value = current_hp
	if current_hp <= 0:
		die()

func die():
	is_alive = false
	play_animation("dead")
	$CollisionShape2D.disabled = true

# -------------------------------------------------------
# TURN RESET
# -------------------------------------------------------

func reset_turn():
	has_moved = false
	has_attacked = false
	
