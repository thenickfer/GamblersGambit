extends "res://Scripts/card_effects/effect_base.gd"

# Agenda um outro efeito para ser executado no INÍCIO do próximo turno do alvo.
# params.effect é um dicionário de efeito normal (mesmo formato de card_db.gd),
# ex.: {"kind": "energy", "value": -1} ou {"kind": "energy", "value": -1, "target": "enemy"}.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.defer_effect(target, params.get("effect", {}), context.card.card_name)
