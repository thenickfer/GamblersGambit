extends "res://Scripts/card_effects/effect_base.gd"

# Sorteia um resultado entre "outcomes" (por peso) e roda seus efeitos aninhados.
# outcomes: [ { "weight": N, "effects": [ ... ] }, ... ]
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var outcomes: Array = context.params.get("outcomes", [])
	if outcomes.is_empty():
		return
	var total := 0
	for o in outcomes:
		total += int(o.get("weight", 1))
	if total <= 0:
		return
	var roll := randi_range(1, total)
	var acc := 0
	for o in outcomes:
		acc += int(o.get("weight", 1))
		if roll <= acc:
			gm.run_effects(context.source, context.target, context.card, o.get("effects", []))
			return
