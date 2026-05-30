## UIManager.gd
## Manages all HUD elements: turn label, unit info panel, end-turn button, game-over screen.
## Attach to a CanvasLayer node called "UIManager".

extends CanvasLayer

@onready var turn_label    : Label  = $TurnLabel
@onready var unit_info     : Label  = $UnitInfoPanel/UnitInfoLabel
@onready var end_turn_btn  : Button = $EndTurnButton
@onready var game_over_panel : Control = $GameOverPanel
@onready var game_over_label : Label   = $GameOverPanel/ResultLabel

var game_manager : Node = null   # set by GameManager._ready()

func _ready() -> void:
	game_over_panel.visible = false
	end_turn_btn.pressed.connect(_on_end_turn_pressed)

func set_turn_label(text: String) -> void:
	turn_label.text = text

func show_unit_info(unit: Node2D) -> void:
	unit_info.text = "%s\nHP: %d/%d\nMov: %d  Atk: %d  Dmg: %d" % [
		unit.unit_name, unit.current_hp, unit.max_hp,
		unit.move_range, unit.attack_range, unit.attack_damage
	]

func clear_unit_info() -> void:
	unit_info.text = "Select a unit"

func show_game_over(player_wins: bool) -> void:
	game_over_panel.visible = true
	game_over_label.text = "Victory!" if player_wins else "Defeat!"
	end_turn_btn.disabled = true

func _on_end_turn_pressed() -> void:
	if game_manager:
		game_manager.end_player_turn()
