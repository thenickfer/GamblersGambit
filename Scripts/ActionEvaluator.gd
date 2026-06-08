class_name ActionEvaluator

const CardDB = preload("res://Scripts/card_db.gd")

static func score(action: Dictionary, state: Dictionary) -> float:
	match action.type:
		"play_card":
			var card = state.hand[action.card_index]
			return _score_card(card, state)

		"end_turn":
			return -100

	return 0
	
static func _score_card(card: Dictionary, state: Dictionary) -> float:
	var score := 0.0

	var my_hp = state.battle_context.self.health
	var enemy_hp = state.battle_context.enemy.health

	match card.action:
		CardDB.Action.ATTACK:
			score += card.value

			if enemy_hp <= card.value:
				score += 1000000

		CardDB.Action.CURE:
			score += max(0, 100 - my_hp) * 0.5
			score += card.value

		CardDB.Action.DEFENCE:
			score += card.value

		CardDB.Action.BUFF:
			score += card.value * 2

		CardDB.Action.DEBUFF:
			score += card.value * 2

	return score
