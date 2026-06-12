extends "res://Scripts/statuses/status_base.gd"

# Reflexão (Reflexo de Bar/Contra-Ataque): devolve value de dano ao atacante.
# Ignora bloqueio do atacante e não tem fonte (evita loop de reflexão).
func on_incoming_attack(gm, _host, attacker, inst) -> void:
	if attacker != null:
		gm.deal_damage(null, attacker, int(inst.get("value", 0)), {"ignore_block": true})
