extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.2
const PLAYER_HAND_SIZE = 5

var player_deck = ["Attack1", "Defence1", "Cure1", "Buff1", "Debuff1", "Energy1"] 
var card_database_reference

#collision layer do deck = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Scripts/card_db.gd") 
	for i in range (PLAYER_HAND_SIZE):
		draw_card()
	$RichTextLabel.text = str(player_deck.size())

func draw_card():
	
	if ($"../PlayerHand".player_hand.size()<5):
		var card_drawn_index = randi_range(0, player_deck.size()-1)
		var card_drawn_name = player_deck[card_drawn_index]
		#print(card_drawn_name) # REMOVER
		player_deck.erase(card_drawn_name)
		var card_scene = preload(CARD_SCENE_PATH)
		var new_card = card_scene.instantiate()
		var card_image_path = str("res://Assets/Cards/" + card_drawn_name + ".png")
		new_card.get_node("CardImage").texture = load(card_image_path)
		new_card.get_node("Action").text = str(displayAction(card_database_reference.CARDS[card_drawn_name][0]))  # Talvez mudar isso no futuro
		new_card.get_node("Value").text = str(card_database_reference.CARDS[card_drawn_name][1])
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
	
# Funcao usada para teste para mostrar a acao da carta em cima da carta
func displayAction(actionValue):
	match actionValue:
		card_database_reference.CardType.ATTACK:
			return "Attack"
		card_database_reference.CardType.DEFENCE:
			return "Defence"
		card_database_reference.CardType.CURE:
			return "Cure"
		card_database_reference.CardType.BUFF:
			return "Buff"
		card_database_reference.CardType.DEBUFF:
			return "Debuff"
		card_database_reference.CardType.ENERGY:
			return "Energy"
