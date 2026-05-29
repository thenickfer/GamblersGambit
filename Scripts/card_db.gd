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
const CARDS = {
	"Espada":       [Action.ATTACK,  6, 0],
	"Escudo":       [Action.DEFENCE, 5, 0],
	"Poção":        [Action.CURE,    4, 0],
	"Fúria":        [Action.BUFF,    2, 5],
	"Veneno":       [Action.DEBUFF,  3, 3],
	"Bola de Fogo": [Action.ATTACK,  9, 0],
	"Muralha":      [Action.DEFENCE, 8, 2],
	"Bênção":       [Action.CURE,    7, 0],
	"Adrenalina":   [Action.BUFF,    3, 3],
	"Maldição":     [Action.DEBUFF,  5, 4],
}
