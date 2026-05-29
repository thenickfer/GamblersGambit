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
var status_by_combatant := {}

@onready var player_combatant = $PlayerStats
@onready var cpu_combatant = $OpponentStats
@onready var turn_label = $TurnLabel
@onready var temp_slots_root = $PlayerTempSlots
@onready var card_manager = $CardManager
@onready var player_hand = $PlayerHand
@onready var deck_node = $Deck
@onready var opponent_slot = $OpponentSlot
@onready var opponent_hand_label = $OpponentHandLabel
@onready var player_fx_label = $PlayerFxLabel
@onready var opponent_fx_label = $OpponentFxLabel
@onready var player_status_label = $PlayerStatusLabel
@onready var opponent_status_label = $OpponentStatusLabel

func _ready() -> void:
	for slot in temp_slots_root.get_children():
		player_temp_slots.append(slot)
		occupied.append(false)

	player_combatant.died.connect(_on_combatant_died)
	cpu_combatant.died.connect(_on_combatant_died)

	_setup_combatants()
	battle_state = BattleState.PLAYER_TURN
	_refresh_turn_label()
	_refresh_opponent_hand_label()
	_refresh_status_labels()

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
	if battle_state != BattleState.PLAYER_TURN or battle_state == BattleState.ENDED:
		return {"accepted": false, "went_to_board": false}

	if not player_combatant.remove_card_from_hand(card_node.card_name):
		return {"accepted": false, "went_to_board": false}

	var went_to_board = _process_card_play(player_combatant, cpu_combatant, card_node)
	if not went_to_board:
		player_combatant.add_to_discard(card_node.card_name)

	if _check_battle_end():
		return {"accepted": true, "went_to_board": went_to_board}

	_end_player_turn()
	return {"accepted": true, "went_to_board": went_to_board}

func _process_card_play(source, target, card_node) -> bool:
	var before_health: int = target.current_health
	var before_source_health: int = source.current_health

	var effect = EFFECTS[card_node.card_action].new()
	effect.execute({"game_manager": self, "source": source, "target": target, "card": card_node})

	_show_health_delta(target, target.current_health - before_health)
	_show_health_delta(source, source.current_health - before_source_health)

	if card_node.card_turns > 0:
		_place_temp_card(card_node, source)
	return false if card_node.card_turns == 0 else true

func _end_player_turn() -> void:
	battle_state = BattleState.CPU_TURN
	_tick_temp_cards()
	if not _check_battle_end():
		_cpu_take_turn()

func _cpu_take_turn() -> void:
	if battle_state == BattleState.ENDED:
		return
	if cpu_combatant.hand.is_empty():
		draw_cpu_card()
	if cpu_combatant.hand.is_empty():
		_end_cpu_turn()
		return

	var idx = randi_range(0, cpu_combatant.hand.size() - 1)
	var card_name: String = cpu_combatant.hand[idx]
	cpu_combatant.hand.remove_at(idx)
	_refresh_opponent_hand_label()
	_show_cpu_card_preview(card_name)

	var card_node = _build_virtual_card(card_name)
	var went_to_board = _process_card_play(cpu_combatant, player_combatant, card_node)
	if not went_to_board:
		cpu_combatant.add_to_discard(card_name)

	if _check_battle_end():
		return
	_end_cpu_turn()

func _end_cpu_turn() -> void:
	turn_number += 1
	draw_cpu_card()
	battle_state = BattleState.PLAYER_TURN
	_refresh_turn_label()

func _build_virtual_card(card_name: String) -> Dictionary:
	var data = CardDB.CARDS[card_name]
	return {"card_name": card_name, "card_action": data[0], "card_value": data[1], "card_turns": data[2]}

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
	_refresh_opponent_hand_label()

func _refresh_opponent_hand_label() -> void:
	var lines: Array[String] = ["Mao CPU:"]
	for i in range(cpu_combatant.hand.size()):
		lines.append("%d. %s" % [i + 1, cpu_combatant.hand[i]])
	opponent_hand_label.text = "\n".join(lines)

func _show_cpu_card_preview(card_name: String) -> void:
	if opponent_slot.card_in_slot and is_instance_valid(opponent_slot.card_node):
		opponent_slot.card_node.queue_free()
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	card_manager.add_child(new_card)
	new_card.setup(card_name)
	new_card.get_node("Area2D/CollisionShape2D").disabled = true
	new_card.global_position = opponent_slot.get_card_snap_position()
	opponent_slot.card_in_slot = true
	opponent_slot.card_node = new_card

func _place_temp_card(card_node, source) -> void:
	if card_node.card_action == CardDB.Action.BUFF:
		_register_status(source, "Furia", card_node.card_turns)
		if source == player_combatant:
			player_attack_bonus += card_node.card_value
	if card_node.card_action == CardDB.Action.DEBUFF:
		_register_status(_other_combatant(source), "Veneno", card_node.card_turns)
		if source == player_combatant:
			cpu_attack_penalty += card_node.card_value

	var idx = _free_slot_index()
	if idx != -1 and card_node is Node and source == player_combatant:
		occupied[idx] = true
		var slot = player_temp_slots[idx]
		card_node.set_meta("on_temp_board", true)
		_snap_temp_card_to_slot(card_node, slot)
		call_deferred("_snap_temp_card_to_slot", card_node, slot)

	temp_cards.append({"card": card_node, "slot": idx, "action": card_node.card_action, "value": card_node.card_value, "remaining": card_node.card_turns, "owner": source})
	_refresh_status_labels()

func _register_status(combatant, status_name: String, turns: int) -> void:
	var key = str(combatant.get_instance_id())
	if not status_by_combatant.has(key):
		status_by_combatant[key] = []
	status_by_combatant[key].append({"name": status_name, "turns": turns})

func _tick_temp_cards() -> void:
	var still_active = []
	for entry in temp_cards:
		entry.remaining -= 1
		if entry.remaining > 0:
			still_active.append(entry)
		else:
			_expire_temp_card(entry)
	temp_cards = still_active
	_tick_statuses()
	_refresh_status_labels()

func _tick_statuses() -> void:
	for key in status_by_combatant.keys():
		var next_statuses = []
		for status in status_by_combatant[key]:
			status.turns -= 1
			if status.turns > 0:
				next_statuses.append(status)
		status_by_combatant[key] = next_statuses

func _refresh_status_labels() -> void:
	player_status_label.text = _format_statuses_for(player_combatant)
	opponent_status_label.text = _format_statuses_for(cpu_combatant)

func _format_statuses_for(combatant) -> String:
	var key = str(combatant.get_instance_id())
	if not status_by_combatant.has(key) or status_by_combatant[key].is_empty():
		return ""
	var pieces: Array[String] = []
	for status in status_by_combatant[key]:
		pieces.append("[■] %s(%d)" % [status.name, status.turns])
	return "  ".join(pieces)

func _show_health_delta(combatant, delta: int) -> void:
	if delta == 0:
		return
	var label = player_fx_label if combatant == player_combatant else opponent_fx_label
	if delta > 0:
		label.text = "+%d" % delta
		label.modulate = Color(0.2, 1.0, 0.2, 1.0)
	else:
		label.text = "%d" % delta
		label.modulate = Color(1.0, 0.25, 0.25, 1.0)
	label.visible = true
	var tween = get_tree().create_tween()
	var start_pos = label.position
	tween.tween_property(label, "position", start_pos + Vector2(0, -20), 0.4)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func():
		label.visible = false
		label.modulate.a = 1.0
		label.position = start_pos
	)

func _expire_temp_card(entry) -> void:
	if entry.owner == player_combatant and entry.action == CardDB.Action.BUFF:
		player_attack_bonus -= entry.value
	elif entry.owner == player_combatant and entry.action == CardDB.Action.DEBUFF:
		cpu_attack_penalty -= entry.value
	if entry.slot != -1:
		occupied[entry.slot] = false
	if entry.card is Node and is_instance_valid(entry.card):
		entry.card.queue_free()

func _other_combatant(combatant):
	return cpu_combatant if combatant == player_combatant else player_combatant

func get_attack_bonus(source) -> int:
	if source == player_combatant:
		return player_attack_bonus
	return 0

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
	turn_label.text = "Batalha Encerrada\nVencedor: %s" % winner.combatant_name
	emit_signal("battle_ended", winner, loser)

func _refresh_turn_label() -> void:
	var txt = "Turno: %d" % turn_number
	if player_attack_bonus > 0:
		txt += "\nMeu ataque: +%d" % player_attack_bonus
	if cpu_attack_penalty > 0:
		txt += "\nAtaque inimigo: -%d" % cpu_attack_penalty
	turn_label.text = txt

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
