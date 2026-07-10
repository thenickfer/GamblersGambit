# Banco de dados das cartas.
# Carregado com preload() pelos outros scripts (não é autoload).

# Categoria de cada carta. Usada para o rótulo "Tipo" e para a arte padrão.
# NÃO determina mais a mecânica: o que a carta faz vem da lista "effects".
enum Action { ATTACK, DEFENCE, CURE, BUFF, DEBUFF, ENERGY }

# Nome que aparece no rótulo "Tipo" da carta.
const ACTION_NAMES = {
	Action.ATTACK:  "Ataque",
	Action.DEFENCE: "Defesa",
	Action.CURE:    "Cura",
	Action.BUFF:    "Buff",
	Action.DEBUFF:  "Debuff",
	Action.ENERGY:  "Energia",
}

# Arte padrão usada por categoria quando uma carta não informa uma arte própria.
const ACTION_ARTS = {
	Action.ATTACK:  "res://Assets/Cards/Attack1.png",
	Action.DEFENCE: "res://Assets/Cards/Defence1.png",
	Action.CURE:    "res://Assets/Cards/Cure1.png",
	Action.BUFF:    "res://Assets/Cards/Buff1.png",
	Action.DEBUFF:  "res://Assets/Cards/Debuff1.png",
	Action.ENERGY:  "res://Assets/Cards/Energy1.png",
}

# Cada carta é um Dictionary:
#   type    -> Action (categoria; define rótulo "Tipo" e arte padrão)
#   rarity  -> "Comum" | "Rara" | "Lendária" | "Chaos" (cosmético por enquanto)
#   cost    -> energia gasta ao jogar a carta
#   art     -> caminho da arte (opcional; usa ACTION_ARTS[type] se ausente)
#   desc    -> texto descritivo (opcional)
#   effects -> lista de efeitos aplicados EM ORDEM ao jogar a carta.
#              Cada efeito é um Dictionary com a chave "kind" e parâmetros.
#              É isto que permite cartas complexas: basta adicionar mais efeitos.
#
# Tipos de efeito (kind) disponíveis (ver Scripts/card_effects/):
#   {"kind": "damage", "value": N, "target": "enemy", "ignore_block": bool, "per_spent": K}
#        -> dano N (+bônus); per_spent: dano = energia_gasta*K (custo X); ignore_block fura defesa
#   {"kind": "heal",   "value": N, "target": "self"}   -> cura N de vida (respeita trava de cura)
#   {"kind": "energy", "value": N, "target": "self"}   -> ganha/rouba N de energia
#   {"kind": "block",  "value": N}                     -> concede N de bloqueio (+buffs de defesa)
#   {"kind": "apply_status", "target": "self"/"enemy", "status": { ... }}
#        -> aplica um status contínuo (ver Scripts/statuses/). O dicionário "status" tem:
#           kind: "attack"|"incoming"|"dot"|"regen"|"defense"|"reflect"; value; mult; blocks_heal;
#           ("dot" = dano por turno; "regen" = energia por turno)
#           e duração por turns (>0, charges 0) OU por charges (>0 = consumido no uso).
#   {"kind": "remove_status", "id": "Veneno", "amount": -1, "target": "enemy"}
#        -> amount<0 remove; amount>=0 reduz o value do status com esse id
#   {"kind": "reflect", "value": N}                    -> ao ser atacado, devolve N (1 uso)
#   {"kind": "chance", "outcomes": [{"weight": W, "effects": [...]}, ...]}  -> sorteia 1 ramo
#   {"kind": "conditional", "condition": {...}, "then": [...], "else": [...]}  -> ramifica
#        condition: {type: "health"|"has_block"|"energy_spent", who, op: "<="|">"|..., value}
#   {"kind": "draw"|"discard", "value": N, "target": "self"}  -> compra/descarta N
#   {"kind": "cost_mod", "amount": A, "charges": C}    -> próximas C cartas custam A a menos
#   {"kind": "defer", "effect": { ...efeito... }, "target": "self"}  -> roda no próx. turno
#
# "target" aceita "self" (quem jogou) ou "enemy" (o oponente). Padrão por efeito:
#   damage -> enemy ; heal/block/apply_status -> self.
# O campo "cost" pode ser "X" (string) = gasta toda a energia (usado com damage.per_spent).
const CARDS = {
	"Espada": {
		"type": Action.ATTACK, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/sword.png",
		"desc": "Causa 6 de dano.",
		"effects": [
			{"kind": "damage", "value": 6},
		],
	},
	"Escudo": {
		"type": Action.DEFENCE, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/shield.png",
		"desc": "Bloqueia 5 de dano.",
		"effects": [
			{"kind": "block", "value": 5},
		],
	},
	"Poção": {
		"type": Action.CURE, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/healing_potion.png",
		"desc": "Recupera 4 de vida.",
		"effects": [
			{"kind": "heal", "value": 4},
		],
	},
	"Fúria": {
		"type": Action.BUFF, "rarity": "Rara", "cost": 2,
		"art": "res://Assets/Cards/Arts/rage.png",
		"desc": "Seus ataques causam +2 de dano por 5 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "attack", "id": "Fúria", "value": 2, "turns": 5}},
		],
	},
	"Veneno": {
		"type": Action.DEBUFF, "rarity": "Rara", "cost": 1,
		"art": "res://Assets/Cards/Arts/poison.png",
		"desc": "Reduz o ataque do inimigo em 3 por 3 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "enemy", "status": {"kind": "attack", "id": "Veneno", "value": -3, "turns": 3}},
		],
	},
	"Bola de Fogo": {
		"type": Action.ATTACK, "rarity": "Rara", "cost": 3,
		"art": "res://Assets/Cards/Arts/fireball.png",
		"desc": "Causa 9 de dano.",
		"effects": [
			{"kind": "damage", "value": 9},
		],
	},
	"Muralha": {
		"type": Action.DEFENCE, "rarity": "Rara", "cost": 3,
		"art": "res://Assets/Cards/Arts/stout_wall.png",
		"desc": "Bloqueia 8 de dano por 2 turnos.",
		"effects": [
			{"kind": "block", "value": 8, "turns": 2},
		],
	},
	"Bênção": {
		"type": Action.CURE, "rarity": "Rara", "cost": 2,
		"art": "res://Assets/Cards/Arts/blessing.png",
		"desc": "Recupera 7 de vida.",
		"effects": [
			{"kind": "heal", "value": 7},
		],
	},
	"Adrenalina": {
		"type": Action.BUFF, "rarity": "Rara", "cost": 2,
		"art": "res://Assets/Cards/Arts/adrenaline.png",
		"desc": "Seus ataques causam +3 de dano por 3 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "attack", "id": "Adrenalina", "value": 3, "turns": 3}},
		],
	},
	"Maldição": {
		"type": Action.DEBUFF, "rarity": "Lendária", "cost": 3,
		"art": "res://Assets/Cards/Arts/curse.png",
		"desc": "Reduz o ataque do inimigo em 5 por 4 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "enemy", "status": {"kind": "attack", "id": "Maldição", "value": -5, "turns": 4}},
		],
	},
	"Bebedeira Total": {
		"type": Action.BUFF, "rarity": "Chaos", "cost": 2,
		"art": "res://Assets/Cards/Arts/total_bender.png",
		"desc": "As próximas 2 cartas custam 1 a menos (mín. 0). No próximo turno você começa com -1 de energia.",
		"effects": [
			{"kind": "cost_mod", "amount": 1, "charges": 2, "target": "self"},
			{"kind": "defer", "effect": {"kind": "energy", "value": -1}, "target": "self"},
		],
	},
	# --- Cartas novas: uma por mecânica do framework ---
	"Cotovelada": {
		"type": Action.ATTACK, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/elbow_strike.png",
		"desc": "Causa 2 de dano e ignora defesa.",
		"effects": [
			{"kind": "damage", "value": 2, "ignore_block": true},
		],
	},
	"Corte Profundo": {
		"type": Action.ATTACK, "rarity": "Rara", "cost": 2,
		"art": "res://Assets/Cards/Arts/deep_bleed.png",
		"desc": "Causa 4 de dano e aplica Sangramento (2) por 3 turnos.",
		"effects": [
			{"kind": "damage", "value": 4},
			{"kind": "apply_status", "target": "enemy", "status": {"kind": "dot", "id": "Sangramento", "value": 2, "turns": 3}},
		],
	},
	"Levantar Guarda": {
		"type": Action.DEFENCE, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/raise_guard.png",
		"desc": "Bloqueia 4 de dano.",
		"effects": [
			{"kind": "block", "value": 4},
		],
	},
	"Reflexo de Bar": {
		"type": Action.DEFENCE, "rarity": "Comum", "cost": 2,
		"art": "res://Assets/Cards/Arts/bar_reflex.png",
		"desc": "Bloqueia 4 de dano e devolve 2 ao atacante.",
		"effects": [
			{"kind": "block", "value": 4},
			{"kind": "reflect", "value": 2},
		],
	},
	"Carta Marcada": {
		"type": Action.BUFF, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/marked_card.png",
		"desc": "Seu próximo ataque causa +2 de dano.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "attack", "id": "Carta Marcada", "value": 2, "charges": 1}},
		],
	},
	"Moeda da Sorte": {
		"type": Action.ATTACK, "rarity": "Chaos", "cost": 1,
		"art": "res://Assets/Cards/Arts/lucky_coin.png",
		"desc": "50% de chance de causar 10 de dano. 50% de causar 6 em você.",
		"effects": [
			{"kind": "chance", "outcomes": [
				{"weight": 50, "effects": [{"kind": "damage", "value": 10, "target": "enemy"}]},
				{"weight": 50, "effects": [{"kind": "damage", "value": 6, "target": "self", "ignore_block": true}]},
			]},
		],
	},
	"Veneno Fraco": {
		"type": Action.DEBUFF, "rarity": "Comum", "cost": 2,
		"art": "res://Assets/Cards/Arts/weak_poison.png",
		"desc": "Aplica Veneno (2) por 2 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "enemy", "status": {"kind": "dot", "id": "Veneno", "value": 2, "turns": 2}},
		],
	},
	# --- Cartas de energia pura ---
	"Gole Rápido": {
		"type": Action.ENERGY, "rarity": "Comum", "cost": 0,
		"art": "res://Assets/Cards/Arts/quick_sip.png",
		"desc": "Ganha 1 de energia.",
		"effects": [
			{"kind": "energy", "value": 1, "target": "self"},
		],
	},
	"Caneca Cheia": {
		"type": Action.ENERGY, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/full_mug.png",
		"desc": "Ganha 3 de energia (líquido +2).",
		"effects": [
			{"kind": "energy", "value": 3, "target": "self"},
		],
	},
	"Roubo de Fichas": {
		"type": Action.ENERGY, "rarity": "Rara", "cost": 1,
		"art": "res://Assets/Cards/Arts/chip_steal.png",
		"desc": "Rouba 2 de energia do inimigo.",
		"effects": [
			{"kind": "energy", "value": -2, "target": "enemy"},
			{"kind": "energy", "value": 2, "target": "self"},
		],
	},
	# --- Cartas de ataque adicionais ---
	"Soco Bêbado": {
		"type": Action.ATTACK, "rarity": "Comum", "cost": 0,
		"art": "res://Assets/Cards/Arts/drunken_punch.png",
		"desc": "Causa 3 de dano.",
		"effects": [
			{"kind": "damage", "value": 3},
		],
	},
	"Caneca na Cabeça": {
		"type": Action.ATTACK, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/mug_smash.png",
		"desc": "Causa 5 de dano.",
		"effects": [
			{"kind": "damage", "value": 5},
		],
	},
	"Garrafada": {
		"type": Action.ATTACK, "rarity": "Comum", "cost": 2,
		"art": "res://Assets/Cards/Arts/bottle_smash.png",
		"desc": "Causa 7 de dano.",
		"effects": [
			{"kind": "damage", "value": 7},
		],
	},
	"Facada Dupla": {
		"type": Action.ATTACK, "rarity": "Rara", "cost": 2,
		"art": "res://Assets/Cards/Arts/double_stab.png",
		"desc": "Causa 4 de dano duas vezes.",
		"effects": [
			{"kind": "damage", "value": 4},
			{"kind": "damage", "value": 4},
		],
	},
	"Última Aposta": {
		"type": Action.ATTACK, "rarity": "Chaos", "cost": "X",
		"art": "res://Assets/Cards/Arts/last_bet.png",
		"desc": "Gasta toda a energia e causa 3 de dano por energia gasta.",
		"effects": [
			{"kind": "damage", "per_spent": 3},
		],
	},
	# --- Energia por turno (duração crescente) ---
	"Fôlego": {
		"type": Action.ENERGY, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/breath.png",
		"desc": "Ganha 1 de energia no início dos seus próximos 2 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "regen", "id": "Fôlego", "value": 1, "turns": 2}},
		],
	},
	"Segundo Fôlego": {
		"type": Action.ENERGY, "rarity": "Comum", "cost": 1,
		"art": "res://Assets/Cards/Arts/second_wind.png",
		"desc": "Ganha 1 de energia no início dos seus próximos 3 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "regen", "id": "Segundo Fôlego", "value": 1, "turns": 3}},
		],
	},
	"Vigor do Tavernista": {
		"type": Action.ENERGY, "rarity": "Rara", "cost": 2,
		"art": "res://Assets/Cards/Arts/tavernkeeper_vigor.png",
		"desc": "Ganha 1 de energia no início dos seus próximos 4 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "regen", "id": "Vigor do Tavernista", "value": 1, "turns": 4}},
		],
	},
	"Maré de Energia": {
		"type": Action.ENERGY, "rarity": "Lendária", "cost": 3,
		"art": "res://Assets/Cards/Arts/energy_tide.png",
		"desc": "Ganha 2 de energia no início dos seus próximos 5 turnos.",
		"effects": [
			{"kind": "apply_status", "target": "self", "status": {"kind": "regen", "id": "Maré de Energia", "value": 2, "turns": 5}},
		],
	},
}
