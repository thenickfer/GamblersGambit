extends Node2D

signal battle_ended(winner, loser)

const CardDB = preload("res://Scripts/card_db.gd")
const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const MAX_HAND_SIZE = 5

const EFFECTS = {
	CardDB.Action.ATTACK: preload("res://Scripts/card_effects/effect_attack.gd"),
	CardDB.Action.CURE: preload("res://Scripts/card_effects/effect_cure.gd"),
	CardDB.Action.ENERGY: preload("res://Scripts/card_effects/effect_energy.gd"),
	CardDB.Action.DEFENCE: preload("res://Scripts/card_effects/effect_defence.gd"),
	CardDB.Action.BUFF: preload("res://Scripts/card_effects/effect_buff.gd"),
	CardDB.Action.DEBUFF: preload("res://Scripts/card_effects/effect_debuff.gd"),
}

enum BattleState { SETUP, PLAYER_TURN, CPU_TURN, ENDED }

var battle_state: int = BattleState.SETUP
var turn_number: int = 1
var player_attack_bonus: int = 0
var cpu_attack_penalty: int = 0
var temp_cards: Array = []
var player_temp_slots: Array = []
var occupied: Array[bool] = []
var action_log: Array[String] = []

@onready var player_combatant = $PlayerStats
@onready var cpu_combatant = $OpponentStats
@onready var turn_label = $TurnLabel
@onready var temp_slots_root = $PlayerTempSlots
@onready var card_manager = $CardManager
@onready var player_hand = $PlayerHand
@onready var deck_node = $Deck

func _ready() -> void:
	for slot in temp_slots_root.get_children():
		player_temp_slots.append(slot)
		occupied.append(false)

	player_combatant.died.connect(_on_combatant_died)
	cpu_combatant.died.connect(_on_combatant_died)

	_setup_combatants()
	battle_state = BattleState.PLAYER_TURN
	_refresh_turn_label()

func _setup_combatants() -> void:
	var player_cards: Array[String] = [
		"Espada", "Espada", "Escudo", "Escudo", "Poção", "Fúria", "Veneno",
		"Bola de Fogo", "Muralha", "Bênção", "Adrenalina", "Maldição",
	]
	var cpu_cards: Array[String] = [
		"Espada", "Escudo", "Poção", "Fúria", "Veneno", "Bola de Fogo", "Muralha",
		"Bênção", "Adrenalina", "Maldição",
	]
	player_combatant.setup_deck(player_cards)
	cpu_combatant.setup_deck(cpu_cards)
	for _i in range(MAX_HAND_SIZE):
		deck_node.draw_card()
		draw_cpu_card()

func try_play_player_card(card_node) -> Dictionary:
	if battle_state != BattleState.PLAYER_TURN:
		return {"accepted": false, "went_to_board": false}
	if battle_state == BattleState.ENDED:
		return {"accepted": false, "went_to_board": false}

	var removed = player_combatant.remove_card_from_hand(card_node.card_name)
	if not removed:
		return {"accepted": false, "went_to_board": false}

	var went_to_board = _process_card_play(player_combatant, cpu_combatant, card_node)
	_log_action("%s jogou %s." % [player_combatant.combatant_name, card_node.card_name])
	if not went_to_board:
		player_combatant.add_to_discard(card_node.card_name)

	if _check_battle_end():
		return {"accepted": true, "went_to_board": went_to_board}

	_end_player_turn()
	return {"accepted": true, "went_to_board": went_to_board}

func _process_card_play(source, target, card_node) -> bool:
	var effect = EFFECTS[card_node.card_action].new()
	effect.execute({
		"game_manager": self,
		"source": source,
		"target": target,
		"card": card_node,
	})
	if card_node.card_turns > 0:
		_place_temp_card(card_node, source)
		_log_action("Efeito temporario ativo por %d turnos." % card_node.card_turns)
		return true
	return false

func _end_player_turn() -> void:
	battle_state = BattleState.CPU_TURN
	_tick_temp_cards()
	if not _check_battle_end():
		_cpu_take_turn()

func _cpu_take_turn() -> void:
	if battle_state == BattleState.ENDED:
		return
	# Placeholder: CPU nao toma decisoes nem aplica efeitos nesta entrega.
	_log_action("%s (placeholder) passou o turno." % cpu_combatant.combatant_name)
	_end_cpu_turn()

func _end_cpu_turn() -> void:
	turn_number += 1
	draw_cpu_card()
	battle_state = BattleState.PLAYER_TURN
	_log_action("Novo turno do jogador.")
	_refresh_turn_label()

func _build_virtual_card(card_name: String) -> Dictionary:
	var data = CardDB.CARDS[card_name]
	return {
		"card_name": card_name,
		"card_action": data[0],
		"card_value": data[1],
		"card_turns": data[2],
	}

func draw_player_card() -> void:
	if player_combatant.hand.size() >= MAX_HAND_SIZE:
		return
	var drawn = player_combatant.draw_random_card()
	if drawn == "":
		return
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	card_manager.add_child(new_card)
	new_card.name = "Card"
	new_card.setup(drawn)
	player_hand.add_card_to_hand(new_card, 0.2)
	new_card.get_node("AnimationPlayer").play("card_flip")

func draw_cpu_card() -> void:
	if cpu_combatant.hand.size() >= MAX_HAND_SIZE:
		return
	cpu_combatant.draw_random_card()

func _place_temp_card(card_node, source) -> void:
	if source == player_combatant and card_node.card_action == CardDB.Action.BUFF:
		player_attack_bonus += card_node.card_value
	elif source == player_combatant and card_node.card_action == CardDB.Action.DEBUFF:
		cpu_attack_penalty += card_node.card_value

	var idx = _free_slot_index()
	if idx != -1 and card_node is Node:
		occupied[idx] = true
		var slot = player_temp_slots[idx]
		card_node.set_meta("on_temp_board", true)
		_snap_temp_card_to_slot(card_node, slot)
		call_deferred("_snap_temp_card_to_slot", card_node, slot)

	temp_cards.append({
		"card": card_node,
		"slot": idx,
		"action": card_node.card_action,
		"value": card_node.card_value,
		"remaining": card_node.card_turns,
		"owner": source,
	})

func _snap_temp_card_to_slot(card, slot) -> void:
	if not is_instance_valid(card) or not is_instance_valid(slot):
		return
	card.global_position = slot.global_position
	card.global_rotation = slot.global_rotation
	card.global_scale = slot.global_scale

func _free_slot_index() -> int:
	for i in range(player_temp_slots.size()):
		if not occupied[i]:
			return i
	return -1

func _tick_temp_cards() -> void:
	var still_active = []
	for entry in temp_cards:
		entry.remaining -= 1
		if entry.remaining > 0:
			still_active.append(entry)
		else:
			_expire_temp_card(entry)
	temp_cards = still_active

func _expire_temp_card(entry) -> void:
	if entry.owner == player_combatant and entry.action == CardDB.Action.BUFF:
		player_attack_bonus -= entry.value
	elif entry.owner == player_combatant and entry.action == CardDB.Action.DEBUFF:
		cpu_attack_penalty -= entry.value
	if entry.slot != -1:
		occupied[entry.slot] = false
	if entry.card is Node and is_instance_valid(entry.card):
		entry.card.queue_free()

func get_attack_bonus(source) -> int:
	if source == player_combatant:
		return player_attack_bonus
	return -cpu_attack_penalty

func _on_combatant_died(_combatant) -> void:
	_check_battle_end()

func _check_battle_end() -> bool:
	if battle_state == BattleState.ENDED:
		return true
	if player_combatant.current_health <= 0:
		_end_battle(cpu_combatant, player_combatant)
		return true
	if cpu_combatant.current_health <= 0:
		_end_battle(player_combatant, cpu_combatant)
		return true
	return false

func _end_battle(winner, loser) -> void:
	battle_state = BattleState.ENDED
	_log_action("Batalha encerrada. Vencedor: %s." % winner.combatant_name)
	turn_label.text = "Batalha Encerrada\nVencedor: %s\n\n%s" % [winner.combatant_name, "\n".join(action_log)]
	emit_signal("battle_ended", winner, loser)

func _refresh_turn_label() -> void:
	var txt = "Turno: %d" % turn_number
	if player_attack_bonus > 0:
		txt += "\nMeu ataque: +%d" % player_attack_bonus
	if cpu_attack_penalty > 0:
		txt += "\nAtaque inimigo: -%d" % cpu_attack_penalty
	if not action_log.is_empty():
		txt += "\n\nAcoes:\n" + "\n".join(action_log)
	turn_label.text = txt

func _log_action(message: String) -> void:
	action_log.append(message)
	if action_log.size() > 6:
		action_log.pop_front()
	_refresh_turn_label()
