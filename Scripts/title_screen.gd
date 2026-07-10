extends Control

@export var fade_duration: float = 1.5
@export var transition_duration: float = 0.6
@export_file("*.tscn") var next_scene: String = "res://Scenes/main_menu.tscn"

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var prompt: Label = $Prompt

var _can_start: bool = false
var _transitioning: bool = false


func _ready() -> void:
	AudioManager.play_music("menu")

	fade_overlay.color = Color(0, 0, 0, 1)
	prompt.modulate.a = 0.0

	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(fade_overlay, "color:a", 0.0, fade_duration)
	fade_in.tween_property(prompt, "modulate:a", 1.0, fade_duration)
	fade_in.chain().tween_callback(_on_fade_in_complete)


func _on_fade_in_complete() -> void:
	_can_start = true
	var pulse := create_tween().set_loops()
	pulse.tween_property(prompt, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_start or _transitioning:
		return
	if event is InputEventMouseMotion:
		return
	if event.is_pressed() and not event.is_echo():
		_start_transition()


func _start_transition() -> void:
	_transitioning = true
	AudioManager.play_sfx("button_click")
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, transition_duration)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(next_scene))
