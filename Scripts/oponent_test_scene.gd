extends Control

const CARD_SCENE_PATH = "res://Scenes/CardScene.tscn"

@onready var op1_button: Button = $Options/Op1Button
@onready var op2_button: Button = $Options/Op2Button
@onready var op3_button: Button = $Options/Op3Button
@onready var coins_label: Label = $CoinsLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
	op1_button.pressed.connect(func() -> void: _try_start_match(20, 0.2))
	op2_button.pressed.connect(func() -> void: _try_start_match(50, 0.5))
	op3_button.pressed.connect(func() -> void: _try_start_match(90, 0.9))
	_refresh_ui()

func _try_start_match(cost: int, difficulty: float) -> void:
	if not GameState.spend_coins(cost):
		message_label.text = "Moedas insuficientes"
		_refresh_ui()
		return

	GameState.set_selected_difficulty(difficulty)
	get_tree().change_scene_to_file(CARD_SCENE_PATH)

func _refresh_ui() -> void:
	coins_label.text = "Moedas: %d" % GameState.player_coins
