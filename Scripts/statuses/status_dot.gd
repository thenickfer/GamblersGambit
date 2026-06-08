extends "res://Scripts/statuses/status_base.gd"

# Dano por turno (Sangramento/Veneno). Ignora bloqueio e não tem atacante (sem reflexão).
func on_tick(gm, host, inst) -> void:
	gm.deal_damage(null, host, int(inst.get("value", 0)), {"ignore_block": true})
