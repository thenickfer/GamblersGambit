extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.2
const PLAYER_HAND_SIZE = 5

var player_deck = ["Exemplo0", "Exemplo1", "Exemplo2", "Exemplo3", "Exemplo4", "Exemplo5", "Exemplo6"]
var card_database_reference

#collision layer do deck = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range (PLAYER_HAND_SIZE):
		draw_card()
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://Scripts/card_db.gd")

func draw_card():
	
	if ($"../PlayerHand".player_hand.size()<5):
		var card_drawn_index = randi_range(0, player_deck.size()-1)
		var card_drawn = player_deck[card_drawn_index]
		print(card_drawn) # REMOVER
		player_deck.erase(card_drawn)
		var card_scene = preload(CARD_SCENE_PATH)
		var new_card = card_scene.instantiate()
		#new_card.get_node
		$"../CardManager".add_child(new_card)
		new_card.name = "Card"
		$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	
	#caso o jogador pegue a ultima carta
	#MUDAR ISSO PARA REINICIAR DECK
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(player_deck.size())
	
