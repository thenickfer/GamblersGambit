enum CardType {ATTACK, DEFENCE, CURE, BUFF, DEBUFF, ENERGY}

const CARDS = { # Action, Effect
	"Attack1" : [CardType.ATTACK, 5],
	"Defence1" : [CardType.DEFENCE, 5],
	"Cure1" : [CardType.CURE, 5],
	"Buff1" : [CardType.BUFF, 5], # Não sei o que 5 quer dizer nesse caso
	"Debuff1" : [CardType.DEBUFF, 5], #Nem aqui
	"Energy1" : [CardType.ENERGY, 2]
}
