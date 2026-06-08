extends "res://Scripts/statuses/status_base.gd"

# Modifica o dano de SAÍDA do dono. Cobre buff de ataque (Fúria), próximo-ataque
# +X (Carta Marcada), dobro (Dados Viciados) e Fraqueza (value negativo no inimigo).
# value = soma fixa ; mult = multiplicador (ex.: 2 = dobro).
func modify_outgoing_damage(_gm, _host, inst, dmg: int) -> int:
	return int(round((dmg + int(inst.get("value", 0))) * float(inst.get("mult", 1.0))))
