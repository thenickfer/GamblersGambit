class_name ActionGenerator

static func generate(state: Dictionary) -> Array:
	var actions := []

	for i in range(state.hand.size()):
		if(state.hand[i].cost > state.battle_context.self.energy):
			continue
		actions.append({
			"type": "play_card",
			"card_index": i
		})
		
	return actions
