extends Control

@export var fade_duration: float = 0.6

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var play_button: Button = $Buttons/PlayButton
@onready var quit_button: Button = $Buttons/QuitButton


func _ready() -> void:
	fade_overlay.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	play_button.grab_focus()


func _on_play_pressed() -> void:
	play_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://Scenes/OponentTestScene.tscn")
	)


func _on_quit_pressed() -> void:
	get_tree().quit()
