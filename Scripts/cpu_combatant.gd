class_name CPUCombatant extends Combatant

const CardDB = preload("res://Scripts/card_db.gd")

var ai_controller: AIController

func setup_ai(difficulty: float) -> void:
	ai_controller = AIController.new(difficulty)

func take_action(context: Dictionary):
	var action = ai_controller.take_turn(
		{
			"battle_context": context,
			"hand": _build_hand_snapshot(hand)
		}
	)
	return action.card_index

func _build_hand_snapshot(hand: Array) -> Array:
	var cards := []
	for card_name in hand:
		var data = CardDB.CARDS[card_name]
		cards.append({
			"name": card_name,
			"action": data.type,
			"cost": data.cost,
			"effects": data.effects,
		})

	return cards
