extends "res://Scripts/card_effects/effect_base.gd"

func execute(context: Dictionary) -> void:
	var source = context.source
	var card = context.card
	source.heal(card.card_value)
