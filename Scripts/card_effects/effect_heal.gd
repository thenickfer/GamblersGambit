extends "res://Scripts/card_effects/effect_base.gd"

# Cura o alvo (padrão: quem joga). Passa pelo game_manager para respeitar trava de cura.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.heal(target, int(params.get("value", 0)))
