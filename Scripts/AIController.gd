class_name AIController  

var difficulty: float
var random = RandomNumberGenerator.new()

func _init(difficulty: float) -> void:
	self.difficulty = clampf(difficulty, 0.0, 1.0)
	random.randomize()

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

	if random.randf() > self.difficulty:
		return actions[random.randi_range(0, actions.size() - 1)]
	return best_action;
	
	
