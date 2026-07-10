class_name AIController  

var difficulty: float
var random = RandomNumberGenerator.new()

func _init(difficulty: float) -> void:
	difficulty = difficulty

func take_turn(state: Dictionary):
	var actions = ActionGenerator.generate(state);
	
	if(actions.is_empty()):
		return {
			"type": "pass_turn",
			"card_index": -1
		};
	
	var best_action = null;
	var best_score = -INF;
	
	for action in actions:
		var score = ActionEvaluator.score(action, state);
		
		if score > best_score:
			best_score = score;
			best_action = action;
	return best_action;
	
	
