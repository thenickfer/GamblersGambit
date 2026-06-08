extends Node2D

signal battle_ended(winner, loser)

const CardDB = preload("res://Scripts/card_db.gd")
const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const MAX_HAND_SIZE = 5

const MENU_FONT = preload("res://Assets/fonts/SuperPixel-m2L8j.ttf")
const MAIN_MENU_SCENE = "res://Scenes/main_menu.tscn"
const TEXT_COLOR = Color(1, 0.95, 0.82, 1)
const TEXT_HIGHLIGHT = Color(1, 0.78, 0.36, 1)

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
var temp_cards: Array = []  # efeitos de varios turnos ativos (mostrados como texto nos StatusLabel)
var status_by_combatant := {}

@onready var player_combatant: Combatant = $PlayerStats
@onready var cpu_combatant: CPUCombatant = $OpponentStats
@onready var turn_label = $TurnLabel
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
	player_combatant.died.connect(_on_combatant_died)
	cpu_combatant.died.connect(_on_combatant_died)
	battle_ended.connect(_on_battle_ended)

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
	cpu_combatant.setup_ai(1)
	for _i in range(MAX_HAND_SIZE):
		deck_node.draw_card()
		draw_cpu_card()
var battle_context_for_cpu: Dictionary
func try_play_player_card(card_node) -> Dictionary:
	battle_context_for_cpu = _build_battle_context()
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

	source.spend_energy(1)
	var effect = EFFECTS[card_node.card_action].new()
	effect.execute({"game_manager": self, "source": source, "target": target, "card": card_node})

	_show_health_delta(target, target.current_health - before_health)
	_show_health_delta(source, source.current_health - before_source_health)

	if card_node.card_turns > 0:
		_place_temp_card(card_node, source)
	# a carta jogada sempre vai pro slot central/descarte; o efeito de varios
	# turnos fica registrado e e mostrado como texto nos StatusLabel
	return false

func _end_player_turn() -> void:
	battle_state = BattleState.CPU_TURN
	_tick_temp_cards()
	if not _check_battle_end():
		_cpu_take_turn()

func _get_status_snapshot(combatant) -> Array:
	var key := str(combatant.get_instance_id())

	if !status_by_combatant.has(key):
		return []

	return status_by_combatant[key].duplicate(true)

func _build_battle_context() -> Dictionary:
	return {
		"turn_number": turn_number,

		"self": {
			"health": cpu_combatant.current_health,
			"max_health": cpu_combatant.max_health,
			"energy": cpu_combatant.current_energy,
			"hand": cpu_combatant.hand.duplicate(),
			"attack_bonus": get_attack_bonus(cpu_combatant),
		},

		"enemy": {
			"health": player_combatant.current_health,
			"max_health": player_combatant.max_health,
			"energy": player_combatant.current_energy,
			"hand_size": player_combatant.hand.size(),
			"attack_bonus": get_attack_bonus(player_combatant),
		},

		"statuses": {
			"self": _get_status_snapshot(cpu_combatant),
			"enemy": _get_status_snapshot(player_combatant),
		}
	}

func _cpu_take_turn() -> void:
	if battle_state == BattleState.ENDED:
		return
	

	var decision: int = cpu_combatant.take_action(battle_context_for_cpu)

	var idx = clampi(decision, 0, cpu_combatant.hand.size()-1)
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
		_register_status(source, card_node.card_name, card_node.card_turns, card_node.card_value, true)
	if card_node.card_action == CardDB.Action.DEBUFF:
		_register_status(_other_combatant(source), card_node.card_name, card_node.card_turns, card_node.card_value, false)

	temp_cards.append({"action": card_node.card_action, "value": card_node.card_value, "remaining": card_node.card_turns, "owner": source})
	_refresh_status_labels()
	_refresh_turn_label()

func _register_status(combatant, status_name: String, turns: int, value: int, is_positive: bool) -> void:
	var key = str(combatant.get_instance_id())
	if not status_by_combatant.has(key):
		status_by_combatant[key] = []
	status_by_combatant[key].append({"name": status_name, "turns": turns, "value": value, "is_positive": is_positive})

func _tick_temp_cards() -> void:
	var still_active = []
	for entry in temp_cards:
		entry.remaining -= 1
		if entry.remaining > 0:
			still_active.append(entry)
	temp_cards = still_active
	_tick_statuses()
	_refresh_status_labels()
	_refresh_turn_label()

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
		var sign_txt = "+" if status.is_positive else "-"
		var turno_txt = "turno" if status.turns == 1 else "turnos"
		pieces.append("%s%d %s (%d %s)" % [sign_txt, status.value, status.name, status.turns, turno_txt])
	return "\n".join(pieces)

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
		if not is_instance_valid(label):
			return
		label.visible = false
		label.modulate.a = 1.0
		label.position = start_pos
	)

func _other_combatant(combatant):
	return cpu_combatant if combatant == player_combatant else player_combatant

# Soma o valor de todas as cartas temporarias ativas de um dono e tipo de acao.
func _sum_temp(owner, action) -> int:
	var total = 0
	for entry in temp_cards:
		if entry.owner == owner and entry.action == action:
			total += entry.value
	return total

# Modificador liquido de ataque de um combatente:
# soma dos buffs nele MENOS soma dos debuffs aplicados nele (jogados pelo oponente).
func get_attack_bonus(source) -> int:
	return _sum_temp(source, CardDB.Action.BUFF) - _sum_temp(_other_combatant(source), CardDB.Action.DEBUFF)

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

# Tela de fim de jogo: vitoria/derrota + botao de voltar ao menu (estilo dos menus).
func _on_battle_ended(winner, _loser) -> void:
	if winner == player_combatant:
		_show_end_screen("VOCÊ VENCEU")
	else:
		_show_end_screen("FIM DE JOGO")

func _show_end_screen(message: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.7)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 40)
	layer.add_child(vbox)

	var title := Label.new()
	title.text = message
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", MENU_FONT)
	title.add_theme_font_size_override("font_size", 90)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)

	var button := Button.new()
	button.text = "VOLTAR AO MENU"
	button.flat = true
	button.add_theme_font_override("font", MENU_FONT)
	button.add_theme_font_size_override("font_size", 40)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", TEXT_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", TEXT_HIGHLIGHT)
	button.add_theme_color_override("font_hover_color", TEXT_HIGHLIGHT)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	button.add_theme_constant_override("outline_size", 6)
	button.pressed.connect(_on_back_to_menu_pressed)
	vbox.add_child(button)
	button.grab_focus()

	get_tree().paused = true

func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _refresh_turn_label() -> void:
	var txt = "Turno: %d" % turn_number
	var my_attack = get_attack_bonus(player_combatant)
	var enemy_attack = get_attack_bonus(cpu_combatant)
	if my_attack != 0:
		txt += "\nMeu ataque: %+d" % my_attack
	if enemy_attack != 0:
		txt += "\nAtaque inimigo: %+d" % enemy_attack
	turn_label.text = txt
