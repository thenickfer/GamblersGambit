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
	var data: Array = CardDB.CARDS[name]
	card_action = data[0]
	card_value = data[1]
	card_turns = data[2]
	$CardImage.set_nome(card_name)
	$CardImage.set_value(card_value)
	$CardImage.set_type(CardDB.ACTION_NAMES[card_action])
	$CardImage.set_turns(card_turns)
	var art_path: String = data[3] if data.size() > 3 else CardDB.ACTION_ARTS[card_action]
	$CardImage.set_art_from_path(art_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
