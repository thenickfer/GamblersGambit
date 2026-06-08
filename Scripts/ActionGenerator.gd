class_name ActionGenerator

static func generate(state: Dictionary) -> Array:
	var actions := []

	for i in range(state.hand.size()):
		actions.append({
			"type": "play_card",
			"card_index": i
		})
		
	return actions
