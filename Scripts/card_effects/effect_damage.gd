extends "res://Scripts/card_effects/effect_base.gd"

# Causa dano ao alvo (padrão: inimigo) pelo pipeline central (bônus + bloqueio + reflexão).
# value      -> dano base
# per_spent  -> se presente, dano = energia_gasta * per_spent (cartas custo X, ex.: All In)
# ignore_block -> ignora o bloqueio do alvo (Cotovelada, Golpe Sujo)
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "enemy"))
	var val := int(params.get("value", 0))
	if params.has("per_spent"):
		val = gm.energy_spent_context * int(params.get("per_spent", 1))
	gm.deal_damage(context.source, target, val, {"ignore_block": bool(params.get("ignore_block", false))})
