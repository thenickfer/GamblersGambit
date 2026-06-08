extends "res://Scripts/statuses/status_base.gd"

# Buff de defesa (Rei da Taverna): soma value ao bloqueio que o dono aplicar.
func on_block(_gm, _host, inst, amount: int) -> int:
	return amount + int(inst.get("value", 0))
