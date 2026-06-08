extends "res://Scripts/card_effects/effect_base.gd"

# Descarta "value" cartas aleatórias da mão do alvo (padrão: quem joga).
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var who = gm.resolve_target(context, params.get("target", "self"))
	gm.discard_cards(who, int(params.get("value", 1)))
