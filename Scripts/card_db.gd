# Banco de dados das cartas.
# Carregado com preload() pelos outros scripts (não é autoload).

# Códigos de ação de cada carta.
enum Action { ATTACK, DEFENCE, CURE, BUFF, DEBUFF, ENERGY }

# Nome que aparece no rótulo "Action" da carta.
const ACTION_NAMES = {
	Action.ATTACK:  "Ataque",
	Action.DEFENCE: "Defesa",
	Action.CURE:    "Cura",
	Action.BUFF:    "Buff",
	Action.DEBUFF:  "Debuff",
	Action.ENERGY:  "Energia",
}

# Cada carta: "Nome" = [ação, valor, turnos]
#   ação   -> um dos Action acima (o que a carta faz)
#   valor  -> o número mostrado no rótulo "Value" (dano, cura, força do efeito, etc.)
#   turnos -> quantos turnos o efeito dura. 0 = instantâneo (acontece na hora).
#            Ex.: ["Fúria", BUFF, 2, 5] = +2 por 5 turnos.
# Arte padrao usada por acao quando uma carta nao informa uma arte propria.
const ACTION_ARTS = {
	Action.ATTACK:  "res://Assets/Cards/Attack1.png",
	Action.DEFENCE: "res://Assets/Cards/Defence1.png",
	Action.CURE:    "res://Assets/Cards/Cure1.png",
	Action.BUFF:    "res://Assets/Cards/Buff1.png",
	Action.DEBUFF:  "res://Assets/Cards/Debuff1.png",
	Action.ENERGY:  "res://Assets/Cards/Energy1.png",
}

const CARDS = {
	"Espada":       [Action.ATTACK,  6, 0, "res://Assets/Cards/Arts/sword.png"],
	"Escudo":       [Action.DEFENCE, 5, 0, "res://Assets/Cards/Arts/shield.png"],
	"Poção":        [Action.CURE,    4, 0, "res://Assets/Cards/Arts/healing_potion.png"],
	"Fúria":        [Action.BUFF,    2, 5, "res://Assets/Cards/Arts/rage.png"],
	"Veneno":       [Action.DEBUFF,  3, 3, "res://Assets/Cards/Arts/poison.png"],
	"Bola de Fogo": [Action.ATTACK,  9, 0, "res://Assets/Cards/Arts/fireball.png"],
	"Muralha":      [Action.DEFENCE, 8, 2, "res://Assets/Cards/Arts/stout_wall.png"],
	"Bênção":       [Action.CURE,    7, 0, "res://Assets/Cards/Arts/blessing.png"],
	"Adrenalina":   [Action.BUFF,    3, 3, "res://Assets/Cards/Arts/adrenaline.png"],
	"Maldição":     [Action.DEBUFF,  5, 4, "res://Assets/Cards/Arts/curse.png"],
}
