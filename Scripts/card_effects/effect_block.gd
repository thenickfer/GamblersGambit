extends "res://Scripts/card_effects/effect_base.gd"

# Concede bloqueio ao alvo (padrão: quem joga). O game_manager soma buffs de defesa ativos.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.apply_block(target, int(params.get("value", 0)))
