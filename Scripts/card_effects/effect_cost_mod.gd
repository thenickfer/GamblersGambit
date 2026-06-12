extends "res://Scripts/card_effects/effect_base.gd"

# Registra um desconto de custo com cargas: cada uma das próximas "charges" cartas
# jogadas pelo alvo custa "amount" de energia a menos (mínimo 0).
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.add_cost_mod(target, int(params.get("amount", 1)), int(params.get("charges", 1)), context.card.card_name)
