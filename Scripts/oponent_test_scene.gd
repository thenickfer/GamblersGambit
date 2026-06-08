extends Control

@onready var op1_button: Button = $Options/Op1Button
@onready var op2_button: Button = $Options/Op2Button
@onready var op3_button: Button = $Options/Op3Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	op1_button.pressed.connect(_on_play_pressed)
	op2_button.pressed.connect(_on_play_pressed)
	op3_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/CardScene.tscn")
