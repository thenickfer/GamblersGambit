extends "res://Scripts/card_effects/effect_base.gd"

# Aplica um status temporário ao alvo (buff/debuff que dura "turns" turnos).
# status: identificador do efeito (ex.: "attack" altera o bônus de ataque).
# is_positive: mostra +/- e define se soma ou subtrai no bônus de ataque.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.add_status(target, {
		"name": context.card.card_name,
		"status": params.get("status", "attack"),
		"value": int(params.get("value", 0)),
		"turns": int(params.get("turns", 0)),
		"is_positive": params.get("is_positive", true),
	})
