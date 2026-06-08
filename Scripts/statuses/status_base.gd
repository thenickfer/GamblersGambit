extends RefCounted
class_name StatusBase

# Comportamento contínuo de um status. Cada status sobrescreve só os hooks que usa.
# inst = dicionário do status guardado no combatente:
#   { kind, id, value, turns, charges, mult, blocks_heal, positive }
#   - turns  > 0 e charges == 0  -> dura por turnos (decrementa a cada turno do dono)
#   - charges > 0                -> dura por usos (consumido quando o hook dispara)

# Chamado no início do turno do dono (ex.: Sangramento/Veneno causam dano).
func on_tick(_gm, _host, _inst) -> void:
	pass

# Modifica o dano que o DONO causa ao atacar.
func modify_outgoing_damage(_gm, _host, _inst, dmg: int) -> int:
	return dmg

# Modifica o dano que o DONO recebe ao ser atacado.
func modify_incoming_damage(_gm, _host, _inst, dmg: int) -> int:
	return dmg

# Disparado quando o DONO é atacado (ex.: reflexão devolve dano ao atacante).
func on_incoming_attack(_gm, _host, _attacker, _inst) -> void:
	pass

# Modifica o valor de bloqueio quando o DONO joga uma carta de defesa.
func on_block(_gm, _host, _inst, amount: int) -> int:
	return amount
