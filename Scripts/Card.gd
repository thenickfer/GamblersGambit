extends Node2D

signal hovered
signal hovered_off

const CardDB = preload("res://Scripts/card_db.gd")

var starting_position
var card_name: String
var card_action: int
var card_value: int
var card_turns: int  # turnos que o efeito dura (0 = instantâneo)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_card_signals(self)

# Configura a carta a partir de uma entrada do card_db.gd.
func setup(name: String) -> void:
	card_name = name
	var data = CardDB.CARDS[name]
	card_action = data[0]
	card_value = data[1]
	card_turns = data[2]
	$Nome.text = name
	$Valor.text = "VALOR: " + str(card_value)
	$Turnos.text = "TURNOS: " + str(card_turns)
	$Tipo.text = CardDB.ACTION_NAMES[card_action]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
