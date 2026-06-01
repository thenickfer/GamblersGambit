extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.2
const PLAYER_HAND_SIZE = 5

const INITIAL_DECK = [
	"Espada", "Espada", "Escudo", "Escudo", "Poção", "Fúria", "Veneno",
	"Bola de Fogo", "Muralha", "Bênção", "Adrenalina", "Maldição",
]

var player_deck = INITIAL_DECK.duplicate()
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
		var card_drawn = player_deck[card_drawn_index]
		player_deck.remove_at(card_drawn_index)
		var card_scene = preload(CARD_SCENE_PATH)
		var new_card = card_scene.instantiate()
		$"../CardManager".add_child(new_card)
		new_card.name = "Card"
		new_card.setup(card_drawn)
		$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
		new_card.get_node("AnimationPlayer").play("card_flip")
	
	#caso o jogador pegue a ultima carta, reinicia o deck com as mesmas cartas
	if player_deck.size() == 0:
		player_deck = INITIAL_DECK.duplicate()

	$RichTextLabel.text = str(player_deck.size())
	
