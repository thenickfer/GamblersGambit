extends "res://Scripts/card_effects/effect_base.gd"

# Testa "condition" e roda "then" (verdadeiro) ou "else" (falso) via run_effects.
# condition: { "type": "health"|"has_block"|"energy_spent", "who": "self"|"enemy",
#              "op": "<"|"<="|">"|">="|"==", "value": N }
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var ok: bool = gm.check_condition(context, params.get("condition", {}))
	var branch: Array = params.get("then", []) if ok else params.get("else", [])
	gm.run_effects(context.source, context.target, context.card, branch)
