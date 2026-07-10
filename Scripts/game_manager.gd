extends Node2D

signal battle_ended(winner, loser)

const CardDB = preload("res://Scripts/card_db.gd")
const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const MAX_HAND_SIZE = 5

const MENU_FONT = preload("res://Assets/fonts/SuperPixel-m2L8j.ttf")
const MAIN_MENU_SCENE = "res://Scenes/main_menu.tscn"
const TEXT_COLOR = Color(1, 0.95, 0.82, 1)
const TEXT_HIGHLIGHT = Color(1, 0.78, 0.36, 1)

# Energia recuperada por cada combatente no início do seu turno (mantém o jogo
# jogável agora que jogar cartas custa energia). Ajuste para balancear.
const ENERGY_REGEN = 1

# Cada efeito de carta é resolvido por um script, indexado pela chave "kind".
const EFFECTS = {
	"damage":        preload("res://Scripts/card_effects/effect_damage.gd"),
	"heal":          preload("res://Scripts/card_effects/effect_heal.gd"),
	"energy":        preload("res://Scripts/card_effects/effect_energy.gd"),
	"block":         preload("res://Scripts/card_effects/effect_block.gd"),
	"apply_status":  preload("res://Scripts/card_effects/effect_apply_status.gd"),
	"remove_status": preload("res://Scripts/card_effects/effect_remove_status.gd"),
	"chance":        preload("res://Scripts/card_effects/effect_chance.gd"),
	"conditional":   preload("res://Scripts/card_effects/effect_conditional.gd"),
	"draw":          preload("res://Scripts/card_effects/effect_draw.gd"),
	"discard":       preload("res://Scripts/card_effects/effect_discard.gd"),
	"reflect":       preload("res://Scripts/card_effects/effect_reflect.gd"),
	"cost_mod":      preload("res://Scripts/card_effects/effect_cost_mod.gd"),
	"defer":         preload("res://Scripts/card_effects/effect_defer.gd"),
}

# Comportamento contínuo de cada status, indexado por inst.kind (ver Scripts/statuses/).
const STATUSES = {
	"attack":   preload("res://Scripts/statuses/status_attack.gd"),
	"incoming": preload("res://Scripts/statuses/status_incoming.gd"),
	"dot":      preload("res://Scripts/statuses/status_dot.gd"),
	"defense":  preload("res://Scripts/statuses/status_defense.gd"),
	"reflect":  preload("res://Scripts/statuses/status_reflect.gd"),
	"regen":    preload("res://Scripts/statuses/status_regen.gd"),
}

enum BattleState { SETUP, PLAYER_TURN, CPU_TURN, ENDED }

var battle_state: int = BattleState.SETUP
var turn_number: int = 1
# Status contínuos ativos por combatente. Chave = id do combatente;
# valor = Array de { kind, id, value, turns, charges, mult, blocks_heal, positive }.
var statuses_by_combatant := {}
# Descontos de custo com cargas (consumidos por carta jogada, não por turno).
# Chave = id do combatente; valor = Array de { amount, charges, name }.
var cost_mods_by_combatant := {}
# Efeitos agendados para o início do próximo turno de cada combatente.
# Chave = id do combatente; valor = Array de { effect, name }.
var pending_turn_start := {}
# Instâncias (sem estado) dos scripts de status, criadas em _ready.
var _status_impl := {}
# Energia gasta na carta que está sendo jogada (para efeitos com custo X, ex.: All In).
var energy_spent_context: int = 0

@onready var player_combatant: Combatant = $PlayerStats
@onready var cpu_combatant: CPUCombatant = $OpponentStats
@onready var turn_label = $TurnLabel
@onready var card_manager = $CardManager
@onready var player_hand = $PlayerHand
@onready var deck_node = $Deck
@onready var opponent_slot = $OpponentSlot
@onready var player_fx_label = $PlayerFxLabel
@onready var opponent_fx_label = $OpponentFxLabel
@onready var player_status_label = $PlayerStatusLabel
@onready var opponent_status_label = $OpponentStatusLabel

func _ready() -> void:
	for k in STATUSES:
		_status_impl[k] = STATUSES[k].new()

	player_combatant.died.connect(_on_combatant_died)
	cpu_combatant.died.connect(_on_combatant_died)
	battle_ended.connect(_on_battle_ended)

	cpu_combatant.cpu_pick_assertiveness = GameState.selected_cpu_assertiveness

	_setup_combatants()
	battle_state = BattleState.PLAYER_TURN
	_refresh_turn_label()
	_refresh_status_labels()

func _setup_combatants() -> void:
	var player_cards: Array[String] = [
		"Espada", "Espada", "Escudo", "Escudo", "Poção", "Fúria", "Veneno",
		"Bola de Fogo", "Muralha", "Bênção", "Adrenalina", "Maldição", "Bebedeira Total",
		# cartas novas para exercitar cada mecânica do framework
		"Cotovelada", "Corte Profundo", "Levantar Guarda", "Reflexo de Bar",
		"Carta Marcada", "Moeda da Sorte", "Veneno Fraco",
	]
	var cpu_cards: Array[String] = [
		"Espada", "Escudo", "Poção", "Fúria", "Veneno", "Bola de Fogo", "Muralha",
		"Bênção", "Adrenalina", "Maldição",
		"Cotovelada", "Corte Profundo", "Levantar Guarda", "Moeda da Sorte",
	]
	player_combatant.setup_deck(player_cards)
	cpu_combatant.setup_deck(cpu_cards)
	cpu_combatant.setup_ai(cpu_combatant.cpu_pick_assertiveness)
	print(cpu_combatant.cpu_pick_assertiveness)
	for _i in range(MAX_HAND_SIZE):
		deck_node.draw_card()
		draw_cpu_card()
var battle_context_for_cpu: Dictionary
func try_play_player_card(card_node) -> Dictionary:
	battle_context_for_cpu = _build_battle_context()
	if battle_state != BattleState.PLAYER_TURN or battle_state == BattleState.ENDED:
		return {"accepted": false, "went_to_board": false}

	var cost = _resolve_cost(player_combatant, card_node.card_cost)
	if not player_combatant.can_afford(cost):
		return {"accepted": false, "went_to_board": false, "reason": "energy"}

	if not player_combatant.remove_card_from_hand(card_node.card_name):
		return {"accepted": false, "went_to_board": false}

	player_combatant.spend_energy(cost)
	energy_spent_context = cost
	_consume_cost_mods(player_combatant)  # antes dos efeitos: não consome o desconto que a própria carta criar

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

	run_effects(source, target, card_node, card_node.card_effects)

	_show_health_delta(target, target.current_health - before_health)
	_show_health_delta(source, source.current_health - before_source_health)
	_refresh_status_labels()
	_refresh_turn_label()
	# a carta jogada sempre vai pro slot central/descarte; os efeitos de varios
	# turnos ficam registrados e sao mostrados como texto nos StatusLabel
	return false

# Executa uma lista de efeitos no contexto (source, target, card). Ponto único
# reusado por: jogada normal, chance, conditional, defer e tick de status.
func run_effects(source, target, card, effects: Array) -> void:
	for effect_data in effects:
		var kind = effect_data.get("kind", "")
		if not EFFECTS.has(kind):
			push_warning("Efeito desconhecido em '%s': %s" % [card.card_name, kind])
			continue
		var effect = EFFECTS[kind].new()
		effect.execute({
			"game_manager": self, "source": source, "target": target,
			"card": card, "params": effect_data,
		})

func _end_player_turn() -> void:
	battle_state = BattleState.CPU_TURN
	_refresh_status_labels()
	_refresh_turn_label()
	if not _check_battle_end():
		_cpu_take_turn()

func _get_status_snapshot(combatant) -> Array:
	var key := str(combatant.get_instance_id())

	if !statuses_by_combatant.has(key):
		return []

	return statuses_by_combatant[key].duplicate(true)

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
	
	_apply_turn_start(cpu_combatant)
	if _check_battle_end():  # dano por turno (Sangramento) pode encerrar a batalha
		return
	if cpu_combatant.hand.is_empty():
		draw_cpu_card()

	# A CPU so pode jogar uma carta que consiga pagar com a energia atual.

	var decision: int = cpu_combatant.take_action(battle_context_for_cpu)

	var idx = clampi(decision, -1, cpu_combatant.hand.size()-1)
	
	if idx == -1:
		_end_cpu_turn()
		return

	var card_name: String = cpu_combatant.hand[idx]
	cpu_combatant.hand.remove_at(idx)
	_show_cpu_card_preview(card_name)

	var card_node = _build_virtual_card(card_name)
	var cost = _resolve_cost(cpu_combatant, card_node.card_cost)
	cpu_combatant.spend_energy(cost)
	energy_spent_context = cost
	_consume_cost_mods(cpu_combatant)
	var went_to_board = _process_card_play(cpu_combatant, player_combatant, card_node)
	if not went_to_board:
		cpu_combatant.add_to_discard(card_name)

	if _check_battle_end():
		return
	_end_cpu_turn()

# Retorna o indice de uma carta que a CPU consegue pagar, ou -1.
# cpu_pick_assertiveness controla a chance de escolher a melhor carta estimada:
# 0.0 = aleatorio entre jogaveis; 1.0 = sempre a maior pontuacao.
func _pick_cpu_card_index() -> int:
	var affordable: Array[Dictionary] = []
	for i in range(cpu_combatant.hand.size()):
		var card_name: String = cpu_combatant.hand[i]
		var base_cost = CardDB.CARDS[card_name].get("cost", 0)
		if cpu_combatant.can_afford(_resolve_cost(cpu_combatant, base_cost)):
			affordable.append({"index": i, "score": _score_cpu_card(card_name)})
	if affordable.is_empty():
		return -1

	var assertiveness := clampf(float(cpu_combatant.cpu_pick_assertiveness), 0.0, 1.0)
	if randf() > assertiveness:
		return int(affordable[randi_range(0, affordable.size() - 1)]["index"])

	var best := affordable[0]
	for option in affordable:
		if float(option["score"]) > float(best["score"]):
			best = option
	return int(best["index"])

func _score_cpu_card(card_name: String) -> float:
	var data: Dictionary = CardDB.CARDS[card_name]
	var cost = _resolve_cost(cpu_combatant, data.get("cost", 0))
	var score := -float(cost) * 0.25
	for effect_data in data.get("effects", []):
		score += _score_cpu_effect(effect_data, cost, 1.0)
	return score

func _score_cpu_effect(effect_data: Dictionary, card_cost: int, weight: float) -> float:
	var kind := String(effect_data.get("kind", ""))
	var score := 0.0
	match kind:
		"damage":
			var damage := int(effect_data.get("value", 0))
			if effect_data.has("per_spent"):
				damage = card_cost * int(effect_data.get("per_spent", 1))
			score += _score_cpu_damage(_cpu_effect_target(effect_data, "enemy"), damage, bool(effect_data.get("ignore_block", false)))
		"heal":
			score += _score_cpu_heal(_cpu_effect_target(effect_data, "self"), int(effect_data.get("value", 0)))
		"energy":
			score += _score_cpu_energy(_cpu_effect_target(effect_data, "self"), int(effect_data.get("value", 0)))
		"block":
			score += _score_cpu_block(_cpu_effect_target(effect_data, "self"), int(effect_data.get("value", 0)))
		"apply_status":
			score += _score_cpu_status(_cpu_effect_target(effect_data, "self"), effect_data.get("status", {}))
		"remove_status":
			var remove_target = _cpu_effect_target(effect_data, "enemy")
			score += 2.0 if remove_target == player_combatant else -2.0
		"reflect":
			score += _score_cpu_block(cpu_combatant, int(effect_data.get("value", 0))) * 0.6
		"chance":
			score += _score_cpu_chance(effect_data, card_cost)
		"conditional":
			score += _score_cpu_conditional(effect_data, card_cost)
		"draw":
			var draw_target = _cpu_effect_target(effect_data, "self")
			score += float(int(effect_data.get("value", 0))) * (1.2 if draw_target == cpu_combatant else -1.2)
		"discard":
			var discard_target = _cpu_effect_target(effect_data, "enemy")
			score += float(int(effect_data.get("value", 0))) * (2.0 if discard_target == player_combatant else -2.0)
		"cost_mod":
			score += float(int(effect_data.get("amount", 1)) * int(effect_data.get("charges", 1))) * 1.2
		"defer":
			score += _score_cpu_effect(effect_data.get("effect", {}), card_cost, 1.0) * 0.6
	return score * weight

func _score_cpu_damage(target, amount: int, ignore_block: bool) -> float:
	var damage := amount
	if target == player_combatant and not ignore_block:
		damage = max(0, damage - int(player_combatant.get("block")))
	if target == cpu_combatant:
		return -float(damage) * 2.5

	var score := float(damage) * 2.5
	if damage >= player_combatant.current_health:
		score += 100.0
	var player_health_ratio :float = float(player_combatant.current_health) / max(1.0, float(player_combatant.max_health))
	if player_health_ratio <= 0.35:
		score += float(damage) * 1.5
	return score

func _score_cpu_heal(target, amount: int) -> float:
	var missing = max(0, target.max_health - target.current_health)
	var useful_heal = min(amount, missing)
	var score := float(useful_heal) * 2.2
	var health_ratio :float = float(target.current_health) / max(1.0, float(target.max_health))
	if health_ratio <= 0.35:
		score *= 1.8
	return score if target == cpu_combatant else -score

func _score_cpu_energy(target, amount: int) -> float:
	if target == cpu_combatant:
		return float(amount) * 0.8
	return -float(amount) * 0.8

func _score_cpu_block(target, amount: int) -> float:
	var score := float(amount) * 1.1
	var cpu_health_ratio : float = float(cpu_combatant.current_health) / max(1.0, float(cpu_combatant.max_health))
	if cpu_health_ratio <= 0.4:
		score *= 1.7
	return score if target == cpu_combatant else -score

func _score_cpu_status(target, status_data) -> float:
	var status: Dictionary = (status_data as Dictionary)
	var kind := String(status.get("kind", ""))
	var value := int(status.get("value", 0))
	var duration :int = max(1, int(status.get("turns", status.get("charges", 1))))
	var score := 0.0
	match kind:
		"attack":
			score = float(value * duration) * 1.6
			score = score if target == cpu_combatant else -score
		"dot":
			score = float(value * duration) * 2.0
			score = score if target == player_combatant else -score
		"defense":
			score = float(value * duration) * 1.1
			score = score if target == cpu_combatant else -score
		"incoming":
			score = float(value * duration) * 1.4
			score = score if target == player_combatant else -score
		"reflect":
			score = float(value * duration) * 1.2
			score = score if target == cpu_combatant else -score
	if bool(status.get("blocks_heal", false)):
		score += 4.0 if target == player_combatant else -4.0
	return score

func _score_cpu_chance(effect_data: Dictionary, card_cost: int) -> float:
	var outcomes: Array = effect_data.get("outcomes", [])
	var total_weight := 0
	var total_score := 0.0
	for outcome in outcomes:
		var outcome_weight := int(outcome.get("weight", 1))
		total_weight += outcome_weight
		for nested_effect in outcome.get("effects", []):
			total_score += _score_cpu_effect(nested_effect, card_cost, float(outcome_weight))
	if total_weight <= 0:
		return 0.0
	return total_score / float(total_weight)

func _score_cpu_conditional(effect_data: Dictionary, card_cost: int) -> float:
	var context := {"source": cpu_combatant, "target": player_combatant}
	var branch: Array = effect_data.get("then", []) if check_condition(context, effect_data.get("condition", {})) else effect_data.get("else", [])
	var score := 0.0
	for nested_effect in branch:
		score += _score_cpu_effect(nested_effect, card_cost, 1.0)
	return score

func _cpu_effect_target(effect_data: Dictionary, default_target: String):
	var target_spec := String(effect_data.get("target", default_target))
	return cpu_combatant if target_spec == "self" else player_combatant

func _end_cpu_turn() -> void:
	turn_number += 1
	draw_cpu_card()
	battle_state = BattleState.PLAYER_TURN
	_apply_turn_start(player_combatant)  # início do próximo turno do jogador
	_check_battle_end()  # dano por turno pode matar o jogador no começo do turno
	_refresh_turn_label()

func _build_virtual_card(card_name: String) -> Dictionary:
	var data: Dictionary = CardDB.CARDS[card_name]
	return {
		"card_name": card_name,
		"card_type": data.get("type", CardDB.Action.ATTACK),
		"card_cost": data.get("cost", 0),
		"card_effects": data.get("effects", []),
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

func _show_cpu_card_preview(card_name: String) -> void:
	if opponent_slot.card_in_slot and is_instance_valid(opponent_slot.card_node):
		opponent_slot.card_node.queue_free()
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	card_manager.add_child(new_card)
	new_card.setup(card_name)
	new_card.scale = card_manager.HAND_CARD_SCALE  # mesmo tamanho das cartas grandes (1.5x)
	new_card.get_node("Area2D/CollisionShape2D").disabled = true
	new_card.global_position = opponent_slot.get_card_snap_position()
	opponent_slot.card_in_slot = true
	opponent_slot.card_node = new_card

# --- Pipeline central de dano ---

# Aplica dano de "source" em "target" compondo: modificadores de ataque do source,
# modificadores de dano de entrada do target, bloqueio (salvo ignore_block) e reflexão.
# source == null (ou source == target) significa dano sem ataque (DoT, autodano).
func deal_damage(source, target, amount: int, flags := {}) -> void:
	if target == null:
		return
	var dmg = amount
	var is_attack = source != null and source != target
	if is_attack:
		dmg = _modify_damage(source, dmg, "modify_outgoing_damage")
	dmg = _modify_damage(target, dmg, "modify_incoming_damage")
	dmg = max(0, dmg)
	target.take_damage(dmg, bool(flags.get("ignore_block", false)))
	if is_attack:
		_trigger_reflect(target, source)
		_consume_charges(source, ["attack"])
		_consume_charges(target, ["incoming"])

# Aplica em sequência o hook indicado de todos os status do combatente.
func _modify_damage(host, dmg: int, hook: String) -> int:
	var key = str(host.get_instance_id())
	if statuses_by_combatant.has(key):
		for inst in statuses_by_combatant[key]:
			var impl = _status_impl.get(inst.get("kind", ""), null)
			if impl != null:
				dmg = impl.call(hook, self, host, inst, dmg)
	return dmg

# Dispara a reflexão dos status do alvo contra o atacante e consome a carga.
func _trigger_reflect(host, attacker) -> void:
	var key = str(host.get_instance_id())
	if not statuses_by_combatant.has(key):
		return
	var remaining = []
	for inst in statuses_by_combatant[key]:
		if inst.get("kind", "") == "reflect":
			_status_impl["reflect"].on_incoming_attack(self, host, attacker, inst)
			inst["charges"] = int(inst.get("charges", 1)) - 1
			if int(inst["charges"]) > 0:
				remaining.append(inst)
		else:
			remaining.append(inst)
	statuses_by_combatant[key] = remaining

# Consome uma carga dos status de carga (charges > 0) dos kinds informados.
func _consume_charges(host, kinds: Array) -> void:
	var key = str(host.get_instance_id())
	if not statuses_by_combatant.has(key):
		return
	var remaining = []
	for inst in statuses_by_combatant[key]:
		if inst.get("kind", "") in kinds and int(inst.get("charges", 0)) > 0:
			inst["charges"] = int(inst["charges"]) - 1
			if int(inst["charges"]) > 0:
				remaining.append(inst)
		else:
			remaining.append(inst)
	statuses_by_combatant[key] = remaining

# Cura respeitando trava de cura (status com blocks_heal).
func heal(combatant, amount: int) -> void:
	if not _can_heal(combatant):
		return
	combatant.heal(amount)

func _can_heal(combatant) -> bool:
	var key = str(combatant.get_instance_id())
	if statuses_by_combatant.has(key):
		for inst in statuses_by_combatant[key]:
			if bool(inst.get("blocks_heal", false)):
				return false
	return true

# Aplica bloqueio somando buffs de defesa ativos (status kind "defense").
func apply_block(combatant, amount: int) -> void:
	var key = str(combatant.get_instance_id())
	if statuses_by_combatant.has(key):
		for inst in statuses_by_combatant[key]:
			if inst.get("kind", "") == "defense":
				amount = _status_impl["defense"].on_block(self, combatant, inst, amount)
	combatant.add_block(amount)
	_refresh_status_labels()

# --- Status ---

# Registra um status no combatente, normalizando os campos padrão.
func add_status(combatant, inst: Dictionary) -> void:
	var s = inst.duplicate(true)
	s["kind"] = String(s.get("kind", "attack"))
	s["id"] = String(s.get("id", "?"))
	s["value"] = int(s.get("value", 0))
	s["turns"] = int(s.get("turns", 0))
	s["charges"] = int(s.get("charges", 0))
	s["mult"] = float(s.get("mult", 1.0))
	s["blocks_heal"] = bool(s.get("blocks_heal", false))
	s["positive"] = bool(s.get("positive", s["value"] >= 0))
	var key = str(combatant.get_instance_id())
	if not statuses_by_combatant.has(key):
		statuses_by_combatant[key] = []
	statuses_by_combatant[key].append(s)
	_refresh_status_labels()
	_refresh_turn_label()

# Remove (amount < 0) ou reduz o value (amount >= 0) de status com o id informado.
func remove_status(combatant, id: String, amount: int) -> void:
	var key = str(combatant.get_instance_id())
	if not statuses_by_combatant.has(key):
		return
	var remaining = []
	for inst in statuses_by_combatant[key]:
		if id != "" and String(inst.get("id", "")) == id:
			if amount < 0:
				continue
			inst["value"] = int(inst.get("value", 0)) - amount
			if int(inst["value"]) > 0:
				remaining.append(inst)
		else:
			remaining.append(inst)
	statuses_by_combatant[key] = remaining
	_refresh_status_labels()
	_refresh_turn_label()

# Início do turno do combatente: dispara on_tick (DoT) e expira durações por turno.
# Status de carga (charges > 0) não expiram por turno.
func _tick_statuses(combatant) -> void:
	var key = str(combatant.get_instance_id())
	if not statuses_by_combatant.has(key):
		return
	for inst in statuses_by_combatant[key].duplicate():
		var impl = _status_impl.get(inst.get("kind", ""), null)
		if impl != null:
			impl.on_tick(self, combatant, inst)
	var remaining = []
	for inst in statuses_by_combatant[key]:
		if int(inst.get("charges", 0)) > 0:
			remaining.append(inst)
		else:
			inst["turns"] = int(inst.get("turns", 0)) - 1
			if int(inst["turns"]) > 0:
				remaining.append(inst)
	statuses_by_combatant[key] = remaining

# --- Condições (para o efeito conditional) ---

func check_condition(context, cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	var who = context.source if cond.get("who", "self") == "self" else context.target
	match cond.get("type", "health"):
		"health":
			return _compare(who.current_health, cond.get("op", "<="), int(cond.get("value", 0)))
		"has_block":
			return who.block > 0
		"energy_spent":
			return _compare(energy_spent_context, cond.get("op", "<"), int(cond.get("value", 0)))
		_:
			return false

func _compare(a: int, op: String, b: int) -> bool:
	match op:
		"<":  return a < b
		"<=": return a <= b
		">":  return a > b
		">=": return a >= b
		"==": return a == b
		"!=": return a != b
	return false

# --- Mão / baralho ---

func draw_cards(combatant, n: int) -> void:
	for _i in range(n):
		if combatant == player_combatant:
			draw_player_card()
		else:
			draw_cpu_card()

func discard_cards(combatant, n: int) -> void:
	for _i in range(n):
		if combatant == player_combatant:
			_discard_player_random()
		elif not combatant.hand.is_empty():
			var idx = randi_range(0, combatant.hand.size() - 1)
			combatant.add_to_discard(combatant.hand[idx])
			combatant.hand.remove_at(idx)

func _discard_player_random() -> void:
	var nodes = player_hand.player_hand
	if nodes.is_empty():
		return
	var node = nodes[randi_range(0, nodes.size() - 1)]
	player_combatant.remove_card_from_hand(node.card_name)
	player_combatant.add_to_discard(node.card_name)
	player_hand.remove_card_from_hand(node)
	node.queue_free()

# Resolve o custo real de uma carta: "X" = toda a energia atual; senão aplica descontos.
func _resolve_cost(combatant, raw_cost) -> int:
	if typeof(raw_cost) == TYPE_STRING:
		return combatant.current_energy
	return get_effective_cost(combatant, int(raw_cost))

func _refresh_status_labels() -> void:
	player_status_label.text = _format_statuses_for(player_combatant)
	opponent_status_label.text = _format_statuses_for(cpu_combatant)

func _format_statuses_for(combatant) -> String:
	var key = str(combatant.get_instance_id())
	var pieces: Array[String] = []
	if statuses_by_combatant.has(key):
		for inst in statuses_by_combatant[key]:
			pieces.append(_format_status(inst))
	if cost_mods_by_combatant.has(key):
		for mod in cost_mods_by_combatant[key]:
			var carta_txt = "carta" if mod.charges == 1 else "cartas"
			pieces.append("-%d custo (próx. %d %s)" % [mod.amount, mod.charges, carta_txt])
	return "\n".join(pieces)

func _format_status(inst) -> String:
	var id = String(inst.get("id", "?"))
	var charges = int(inst.get("charges", 0))
	if charges > 0:
		return "%s (próx. %d)" % [id, charges]
	var turns = int(inst.get("turns", 0))
	var turno_txt = "turno" if turns == 1 else "turnos"
	return "%s (%d %s)" % [id, turns, turno_txt]

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

# Resolve o alvo de um efeito a partir do "target" ("self" = quem jogou,
# "enemy" = o oponente). Padrao: inimigo.
func resolve_target(context: Dictionary, spec: String):
	match spec:
		"self": return context.source
		_:      return context.target

func _opponent_of(combatant):
	return cpu_combatant if combatant == player_combatant else player_combatant

# --- Descontos de custo (consumidos por carta jogada) ---

# Custo efetivo de uma carta para um combatente, ja com os descontos ativos.
func get_effective_cost(combatant, base_cost: int) -> int:
	var discount = 0
	var key = str(combatant.get_instance_id())
	if cost_mods_by_combatant.has(key):
		for mod in cost_mods_by_combatant[key]:
			discount += mod.amount
	return max(0, base_cost - discount)

# Registra um desconto de custo com cargas. Chamado pelo efeito "cost_mod".
func add_cost_mod(combatant, amount: int, charges: int, source_name: String) -> void:
	var key = str(combatant.get_instance_id())
	if not cost_mods_by_combatant.has(key):
		cost_mods_by_combatant[key] = []
	cost_mods_by_combatant[key].append({"amount": amount, "charges": charges, "name": source_name})
	_refresh_status_labels()

# Consome uma carga de cada desconto ativo (uma carta foi jogada).
func _consume_cost_mods(combatant) -> void:
	var key = str(combatant.get_instance_id())
	if not cost_mods_by_combatant.has(key):
		return
	var still_active = []
	for mod in cost_mods_by_combatant[key]:
		mod.charges -= 1
		if mod.charges > 0:
			still_active.append(mod)
	cost_mods_by_combatant[key] = still_active
	_refresh_status_labels()

# --- Efeitos adiados para o inicio do proximo turno ---

# Agenda um efeito para o inicio do proximo turno do combatente. Chamado por "defer".
func defer_effect(combatant, effect_data: Dictionary, source_name: String) -> void:
	var key = str(combatant.get_instance_id())
	if not pending_turn_start.has(key):
		pending_turn_start[key] = []
	pending_turn_start[key].append({"effect": effect_data, "name": source_name})

# Início do turno de um combatente: zera bloqueio, aplica DoT/expira status,
# regenera energia e dispara os efeitos adiados.
func _apply_turn_start(combatant) -> void:
	combatant.reset_block()
	var before = combatant.current_health
	_tick_statuses(combatant)
	_show_health_delta(combatant, combatant.current_health - before)
	combatant.gain_energy(ENERGY_REGEN)
	var key = str(combatant.get_instance_id())
	if pending_turn_start.has(key):
		for entry in pending_turn_start[key]:
			_run_effect(combatant, entry.effect, entry.name)
		pending_turn_start.erase(key)
	_refresh_status_labels()

# Executa um unico efeito fora do fluxo de jogar carta (ex.: efeitos adiados).
func _run_effect(combatant, effect_data: Dictionary, source_name: String) -> void:
	var before = combatant.current_health
	run_effects(combatant, _opponent_of(combatant), {"card_name": source_name}, [effect_data])
	_show_health_delta(combatant, combatant.current_health - before)

# Bônus de ataque exibido no rótulo de turno: soma dos status "attack" por turno
# (cargas, ex.: próximo-ataque, não entram nessa conta).
func get_attack_bonus(combatant) -> int:
	var total = 0
	var key = str(combatant.get_instance_id())
	if statuses_by_combatant.has(key):
		for inst in statuses_by_combatant[key]:
			if inst.get("kind", "") == "attack" and int(inst.get("charges", 0)) == 0:
				total += int(inst.get("value", 0))
	return total

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
	GameState.resolve_match(winner == player_combatant)
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
