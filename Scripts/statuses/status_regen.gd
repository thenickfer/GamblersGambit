extends "res://Scripts/statuses/status_base.gd"

# Energia por turno (regeneração). No início do turno do dono, concede "value" de
# energia. Dura por "turns" (expira normalmente) — o espelho de "dot" para energia.
func on_tick(_gm, host, inst) -> void:
	host.gain_energy(int(inst.get("value", 0)))
