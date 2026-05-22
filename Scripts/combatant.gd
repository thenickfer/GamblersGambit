extends Label

# Representa um combatente (player ou oponente): guarda vida e energia
# e atualiza o proprio texto. As cartas chamam take_damage/heal/spend_energy
# neste no para aplicar seus efeitos.

signal died(combatant)

@export var combatant_name: String = "Player"
@export var max_health: int = 20
@export var max_energy: int = 10
@export var start_health: int = -1  # -1 = comeca com vida cheia (max_health)
@export var start_energy: int = -1  # -1 = comeca com energia cheia (max_energy)

var health: int
var energy: int

func _ready() -> void:
	health = start_health if start_health >= 0 else max_health
	energy = start_energy if start_energy >= 0 else max_energy
	_refresh()

func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	_refresh()
	if health == 0:
		emit_signal("died", self)

func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	_refresh()

# Tenta gastar energia. Retorna false (sem gastar) se nao houver o suficiente.
func spend_energy(amount: int) -> bool:
	if energy < amount:
		return false
	energy = clampi(energy - amount, 0, max_energy)
	_refresh()
	return true

func gain_energy(amount: int) -> void:
	energy = clampi(energy + amount, 0, max_energy)
	_refresh()

func _refresh() -> void:
	text = "%s\nVida: %d/%d\nEnergia: %d/%d" % [combatant_name, health, max_health, energy, max_energy]
