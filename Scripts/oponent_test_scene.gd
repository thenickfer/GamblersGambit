extends Control

const CARD_SCENE_PATH = "res://Scenes/CardScene.tscn"
const MAIN_MENU_SCENE_PATH = "res://Scenes/main_menu.tscn"
const MENU_FONT = preload("res://Assets/fonts/SuperPixel-m2L8j.ttf")
const TEXT_COLOR = Color(1, 0.95, 0.82, 1)
const TEXT_HIGHLIGHT = Color(1, 0.78, 0.36, 1)

@onready var op1_button: Button = $Options/Op1Button
@onready var op2_button: Button = $Options/Op2Button
@onready var op3_button: Button = $Options/Op3Button
@onready var coins_label: Label = $CoinsLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
	op1_button.pressed.connect(func() -> void: _try_start_match(20, 0.2))
	op2_button.pressed.connect(func() -> void: _try_start_match(40, 0.4))
	op3_button.pressed.connect(func() -> void: _try_start_match(80, 0.8))
	_refresh_ui()
	_show_terminal_screen_if_needed()

func _try_start_match(cost: int, difficulty: float) -> void:
	if not GameState.spend_coins(cost):
		message_label.text = "Moedas insuficientes"
		_refresh_ui()
		return

	GameState.set_selected_match(cost, difficulty)
	get_tree().change_scene_to_file(CARD_SCENE_PATH)

func _refresh_ui() -> void:
	coins_label.text = "Moedas: %d" % GameState.player_coins

func _show_terminal_screen_if_needed() -> void:
	if GameState.has_winning_coins():
		_set_options_disabled(true)
		_show_terminal_screen("VOCE VENCEU O JOGO", "Moedas: %d/%d" % [GameState.player_coins, GameState.WIN_COINS])
	elif GameState.has_no_coins():
		_set_options_disabled(true)
		_show_terminal_screen("GAME OVER", "Voce ficou sem moedas")

func _set_options_disabled(disabled: bool) -> void:
	op1_button.disabled = disabled
	op2_button.disabled = disabled
	op3_button.disabled = disabled

func _show_terminal_screen(message: String, detail: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 36)
	layer.add_child(vbox)

	var title := Label.new()
	title.text = message
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", MENU_FONT)
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = detail
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", MENU_FONT)
	subtitle.add_theme_font_size_override("font_size", 38)
	subtitle.add_theme_color_override("font_color", TEXT_COLOR)
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	subtitle.add_theme_constant_override("outline_size", 6)
	vbox.add_child(subtitle)

	var button := Button.new()
	button.text = "VOLTAR AO MENU"
	button.flat = true
	button.add_theme_font_override("font", MENU_FONT)
	button.add_theme_font_size_override("font_size", 38)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", TEXT_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", TEXT_HIGHLIGHT)
	button.add_theme_color_override("font_hover_color", TEXT_HIGHLIGHT)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	button.add_theme_constant_override("outline_size", 6)
	button.pressed.connect(_on_terminal_back_pressed)
	vbox.add_child(button)
	button.grab_focus()

func _on_terminal_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
