extends Node2D

#const HAND_COUNT = 5

const CARD_WIDTH = 240      # cartas mais próximas (tamanho continua 1.5x)
const HAND_Y_POSITION = 900 # sobe a mão para a carta 1.5x não cortar embaixo
const DEFAULT_CARD_MOVE_SPEED = 0.2
const HAND_CARD_SCALE = Vector2(1.5, 1.5)

var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = $HandCenter.global_position.x
		
func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0,card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)
	
func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.scale = HAND_CARD_SCALE
		card.starting_position = new_position
		animate_card_to_position (card, new_position, speed)
		
func calculate_card_position(index):
	var x_offset = (player_hand.size() - 1) * CARD_WIDTH
	var x_position = center_screen_x + index * CARD_WIDTH - x_offset /2
	return x_position

func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)
	
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
