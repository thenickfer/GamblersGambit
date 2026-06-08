extends "res://Scripts/card_effects/effect_base.gd"

# Remove ou reduz um status pelo id. amount < 0 remove totalmente; amount >= 0 reduz o value.
func execute(context: Dictionary) -> void:
	var gm = context.game_manager
	var params: Dictionary = context.params
	var target = gm.resolve_target(context, params.get("target", "self"))
	gm.remove_status(target, String(params.get("id", "")), int(params.get("amount", -1)))
