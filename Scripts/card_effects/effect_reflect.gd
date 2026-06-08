extends "res://Scripts/card_effects/effect_base.gd"

# Registra um status de reflexão no alvo (padrão: quem joga): ao ser atacado,
# devolve "value" de dano ao atacante uma vez.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.add_status(target, {
		"kind": "reflect", "id": context.card.card_name,
		"value": int(params.get("value", 0)), "charges": 1,
	})
