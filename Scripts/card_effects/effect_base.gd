extends RefCounted
class_name EffectBase

# Cada efeito de uma carta é executado por um destes scripts.
# context = {
#   "game_manager": GameManager,  # acesso a helpers (resolve_target, get_attack_bonus, add_status)
#   "source": Combatant,          # quem jogou a carta
#   "target": Combatant,          # o oponente de source
#   "card": Card | Dictionary,    # a carta jogada (card_name, card_type, card_cost, card_effects)
#   "params": Dictionary,         # o próprio dicionário do efeito (value, turns, target, ...)
# }
func execute(_context: Dictionary) -> void:
	pass
