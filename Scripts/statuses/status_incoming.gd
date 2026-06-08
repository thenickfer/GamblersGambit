extends "res://Scripts/statuses/status_base.gd"

# Modifica o dano de ENTRADA do dono. value positivo = Vulnerável (recebe mais).
func modify_incoming_damage(_gm, _host, inst, dmg: int) -> int:
	return dmg + int(inst.get("value", 0))
