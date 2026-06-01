extends Node2D

# Coordena o estado do jogo: turnos, efeitos das cartas e cartas temporarias.
#   ATTACK  -> dano imediato no oponente (somando os BUFFs ativos)
#   CURE    -> cura imediata no player
#   ENERGY  -> energia imediata no player
#   BUFF    -> meus ataques causam +X de dano por Y turnos
#   DEBUFF  -> ataques do oponente causam -X de dano por Y turnos
#   DEFENCE -> sem sistema de escudo ainda
# Cartas com turnos > 0 vao para o board de cartas temporarias e ficam ativas
# ate o numero de turnos delas acabar. Por enquanto o oponente nao ataca.

const CardDB = preload("res://Scripts/card_db.gd")
const MENU_FONT = preload("res://src/global_assets/fonts/SuperPixel-m2L8j.ttf")
const MAIN_MENU_SCENE = "res://src/scenes/main_menu/main_menu.tscn"
const TEXT_COLOR = Color(1, 0.95, 0.82, 1)
const TEXT_HIGHLIGHT = Color(1, 0.78, 0.36, 1)

var turn_number: int = 1
var game_over: bool = false

var player_attack_bonus: int = 0      # quanto a MAIS os meus ataques causam
var opponent_attack_penalty: int = 0  # quanto a MENOS os ataques do oponente causam

# Cartas temporarias ativas no board. Cada item:
#   {"card": Node, "slot": int, "action": int, "value": int, "remaining": int}
var temp_cards = []
var player_temp_slots = []  # Marker2D que marcam onde cada carta temporaria fica
var occupied = []           # bool por slot

@onready var player_stats = $PlayerStats
@onready var opponent_stats = $OpponentStats
@onready var turn_label = $TurnLabel
@onready var temp_slots_root = $PlayerTempSlots

func _ready() -> void:
	for slot in temp_slots_root.get_children():
		player_temp_slots.append(slot)
		occupied.append(false)
	player_stats.died.connect(_on_combatant_died)
	opponent_stats.died.connect(_on_combatant_died)
	_refresh_turn_label()

func _on_combatant_died(combatant) -> void:
	if game_over:
		return
	game_over = true
	if combatant == opponent_stats:
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

# Chamado pelo CardManager ao jogar uma carta no slot do player.
# Retorna true se a carta foi para o board temporario (nesse caso o CardManager
# NAO deve coloca-la no slot central do player).
func play_card(card) -> bool:
	# 1) efeito imediato
	match card.card_action:
		CardDB.Action.ATTACK:
			opponent_stats.take_damage(card.card_value + player_attack_bonus)
		CardDB.Action.CURE:
			player_stats.heal(card.card_value)
		CardDB.Action.ENERGY:
			player_stats.gain_energy(card.card_value)
		_:
			pass  # DEFENCE sem sistema; BUFF/DEBUFF ativados ao ir pro board
	# 2) passa o turno (envelhece as temporarias que ja estavam ativas)
	end_turn()
	# 3) carta de varios turnos -> vai pro board e fica ativa
	if card.card_turns > 0:
		_place_temp_card(card)
		_refresh_turn_label()
		return true
	_refresh_turn_label()
	return false

func _place_temp_card(card) -> void:
	# ativa o modificador de dano da carta
	if card.card_action == CardDB.Action.BUFF:
		player_attack_bonus += card.card_value
	elif card.card_action == CardDB.Action.DEBUFF:
		opponent_attack_penalty += card.card_value
	# posiciona o sprite da carta num retangulo livre do board
	var idx = _free_slot_index()
	if idx != -1:
		occupied[idx] = true
		var slot = player_temp_slots[idx]
		card.set_meta("on_temp_board", true)
		_snap_temp_card_to_slot(card, slot)
		call_deferred("_snap_temp_card_to_slot", card, slot)
	temp_cards.append({
		"card": card,
		"slot": idx,
		"action": card.card_action,
		"value": card.card_value,
		"remaining": card.card_turns,
	})

func _snap_temp_card_to_slot(card, slot) -> void:
	if not is_instance_valid(card) or not is_instance_valid(slot):
		return
	# copia explicitamente para nao manter a escala do drag/hover
	card.global_position = slot.global_position
	card.global_rotation = slot.global_rotation
	card.global_scale = slot.global_scale

func _free_slot_index() -> int:
	for i in range(player_temp_slots.size()):
		if not occupied[i]:
			return i
	return -1

func end_turn() -> void:
	turn_number += 1
	_tick_temp_cards()

# Envelhece cada carta temporaria; ao expirar remove efeito + sprite + libera o slot.
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
	if entry.action == CardDB.Action.BUFF:
		player_attack_bonus -= entry.value
	elif entry.action == CardDB.Action.DEBUFF:
		opponent_attack_penalty -= entry.value
	if entry.slot != -1:
		occupied[entry.slot] = false
	if is_instance_valid(entry.card):
		entry.card.queue_free()

# Dano que um ataque do oponente causaria, ja descontando os debuffs ativos.
func opponent_attack_damage(base: int) -> int:
	return max(0, base - opponent_attack_penalty)

func _refresh_turn_label() -> void:
	var txt = "Turno: %d" % turn_number
	if player_attack_bonus > 0:
		txt += "\nMeu ataque: +%d" % player_attack_bonus
	if opponent_attack_penalty > 0:
		txt += "\nAtaque inimigo: -%d" % opponent_attack_penalty
	turn_label.text = txt
