## UIManager.gd
## Manages all HUD elements: turn label, unit info panel, end-turn button,
## game-over screen, and restart button.
## Attach to a CanvasLayer node called "UIManager" (child of GameManager).

extends CanvasLayer

# ------------------------------------------------------------------ #
#  Child references (must match scenes/main.tscn hierarchy)            #
# ------------------------------------------------------------------ #
@onready var turn_label       : Label   = $TurnLabel
@onready var unit_info        : Label   = $UnitInfoPanel/UnitInfoLabel
@onready var end_turn_btn     : Button  = $EndTurnButton
@onready var game_over_panel  : Control = $GameOverPanel
@onready var result_label     : Label   = $GameOverPanel/VBox/ResultLabel
@onready var restart_button   : Button  = $GameOverPanel/VBox/RestartButton

# Set by GameManager._ready()
var game_manager : Node = null

# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #
func _ready() -> void:
	game_over_panel.visible = false
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	else:
		push_error("UIManager: RestartButton not found — check path GameOverPanel/VBox/RestartButton in main.tscn")

# ------------------------------------------------------------------ #
#  Public API                                                          #
# ------------------------------------------------------------------ #
func set_turn_label(text: String) -> void:
	turn_label.text = text

func show_unit_info(unit: Node2D) -> void:
	var done_tag : String = " [DONE]" if unit.is_done() else ""
	unit_info.text = "%s%s\nHP: %d / %d\nMove: %d  Atk Range: %d  Dmg: %d" % [
		unit.unit_name, done_tag,
		unit.current_hp, unit.max_hp,
		unit.move_range, unit.attack_range, unit.attack_damage
	]

func clear_unit_info() -> void:
	unit_info.text = "Select a unit"

func show_game_over(player_wins: bool) -> void:
	game_over_panel.visible = true
	result_label.text       = "Victory!" if player_wins else "Defeat!"
	end_turn_btn.disabled   = true

# ------------------------------------------------------------------ #
#  Button handlers                                                     #
# ------------------------------------------------------------------ #
func _on_end_turn_pressed() -> void:
	if game_manager and is_instance_valid(game_manager):
		game_manager.end_player_turn()

func _on_restart_pressed() -> void:
	if game_manager and is_instance_valid(game_manager):
		game_manager.restart_game()
