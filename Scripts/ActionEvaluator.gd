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
			for effect in card.effects:
				if effect.kind == "damage":
					score += effect.value
					if enemy_hp <= effect.value:
						score += 1000000

		CardDB.Action.CURE:
			score += max(0, 100 - my_hp) * 0.5
			for effect in card.effects:
				if effect.kind == "heal":
					score += effect.value

		CardDB.Action.DEFENCE:
			for effect in card.effects:
				if effect.kind == "block":
					score += effect.value
				
		CardDB.Action.BUFF:
			var aux := 3 if (state.battle_context.turn_number < 5) else 1
			for effect in card.effects:
				score += effect.status.value * (aux + effect.status.turns)
			

		CardDB.Action.DEBUFF:
			for effect in card.effects:
				score += effect.status.value * 2 + effect.status.turns

	return score
