extends Control

@export var fade_duration: float = 0.6

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var play_button: Button = $Buttons/PlayButton
@onready var settings_button: Button = $Buttons/SettingsButton
@onready var quit_button: Button = $Buttons/QuitButton
@onready var settings_panel: Control = $SettingsPanel
@onready var volume_slider: HSlider = $SettingsPanel/Panel/Margin/VBox/VolumeRow/VolumeSlider
@onready var fullscreen_check: CheckBox = $SettingsPanel/Panel/Margin/VBox/FullscreenRow/FullscreenCheck
@onready var back_button: Button = $SettingsPanel/Panel/Margin/VBox/BackButton


func _ready() -> void:
	fade_overlay.color = Color(0, 0, 0, 1)
	settings_panel.hide()
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	play_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://Scenes/CardScene.tscn")
	)


func _on_settings_pressed() -> void:
	settings_panel.show()
	back_button.grab_focus()


func _on_back_pressed() -> void:
	settings_panel.hide()
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_mute(0, value <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))


func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)
