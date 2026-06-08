extends Node2D

signal hovered
signal hovered_off

const CardDB = preload("res://Scripts/card_db.gd")

var starting_position
var card_name: String
var card_type: int       # Action (categoria; rótulo "Tipo" e arte padrão)
var card_cost            # energia gasta ao jogar (int, ou "X" = toda a energia)
var card_effects: Array  # lista de efeitos aplicados ao jogar (ver card_db.gd)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_card_signals(self)

# Configura a carta a partir de uma entrada do card_db.gd.
func setup(name: String) -> void:
	card_name = name
	var data: Dictionary = CardDB.CARDS[name]
	card_type = data.get("type", CardDB.Action.ATTACK)
	card_cost = data.get("cost", 0)
	card_effects = data.get("effects", [])
	$Nome.text = name
	$Custo.text = "CUSTO: " + str(card_cost)
	$Descricao.text = data.get("desc", "")
	$Tipo.text = CardDB.ACTION_NAMES[card_type]
	var art_path: String = data.get("art", CardDB.ACTION_ARTS[card_type])
	$CardImage.set_art_from_path(art_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
