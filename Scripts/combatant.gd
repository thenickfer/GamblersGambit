extends Label

signal died(combatant)

@export var combatant_name: String = "Player"
@export var max_health: int = 20
@export var start_health: int = -1
@export var max_energy: int = 10
@export var start_energy: int = -1

var current_health: int
var current_energy: int
var hand: Array = []
var deck: Array[String] = []
var discard: Array = []
var is_alive: bool = true

func _ready() -> void:
	current_health = start_health if start_health >= 0 else max_health
	current_energy = start_energy if start_energy >= 0 else max_energy
	is_alive = current_health > 0
	_refresh()

func setup_deck(cards: Array) -> void:
	deck.clear()
	for card_name in cards:
		deck.append(String(card_name))
	hand.clear()
	discard.clear()

func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	if current_health <= 0 and is_alive:
		is_alive = false
		emit_signal("died", self)
	_refresh()

func heal(amount: int) -> void:
	if not is_alive:
		return
	current_health = clampi(current_health + amount, 0, max_health)
	_refresh()

func gain_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	_refresh()

func draw_random_card() -> String:
	if deck.is_empty():
		return ""
	var idx = randi_range(0, deck.size() - 1)
	var drawn = deck[idx]
	deck.remove_at(idx)
	hand.append(drawn)
	return drawn

func remove_card_from_hand(card_name: String) -> bool:
	var idx = hand.find(card_name)
	if idx == -1:
		return false
	hand.remove_at(idx)
	return true

func add_to_discard(card_ref) -> void:
	discard.append(card_ref)

func _refresh() -> void:
	text = "%s\nVida: %d/%d\nEnergia: %d/%d" % [combatant_name, current_health, max_health, current_energy, max_energy]
