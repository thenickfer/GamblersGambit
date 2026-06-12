extends "res://Scripts/card_effects/effect_base.gd"

# Aplica um status contínuo ao alvo. params.status é o dicionário do status
# (ver Scripts/statuses/status_base.gd): { kind, value, turns/charges, mult, blocks_heal, id }.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	var inst: Dictionary = (params.get("status", {}) as Dictionary).duplicate(true)
	if not inst.has("id"):
		inst["id"] = context.card.card_name
	gm.add_status(target, inst)
