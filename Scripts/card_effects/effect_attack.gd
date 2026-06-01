extends "res://Scripts/card_effects/effect_base.gd"

func execute(context: Dictionary) -> void:
	var source = context.source
	var target = context.target
	var card = context.card
	var bonus = context.game_manager.get_attack_bonus(source)
	target.take_damage(max(0, card.card_value + bonus))
