# Áudio — como preencher

O `Scripts/audio_manager.gd` (autoload `AudioManager`) procura os arquivos abaixo.
**O jogo roda mesmo sem eles** — cada som ausente simplesmente não toca. Baixe,
renomeie exatamente como abaixo e solte na pasta correspondente. O Godot importa
automaticamente ao focar o editor.

## Music/  (`.ogg`, deixe **Loop** LIGADO no dock de Import)

| Arquivo            | Onde toca            | Sugestão de busca |
|--------------------|----------------------|-------------------|
| `menu_theme.ogg`   | Título + Menu        | "tavern loop", "medieval inn" |
| `combat_theme.ogg` | Cena de combate      | "battle loop", "boss fight loop" |

## SFX/  (`.ogg`)

### Universais
| Arquivo            | Quando toca                         | Sugestão |
|--------------------|-------------------------------------|----------|
| `card_draw.ogg`    | ao comprar carta (flip)             | folhear/whoosh de papel |
| `card_place.ogg`   | ao encaixar a carta no slot         | "card tap"/"snap" na mesa |
| `hit.ogg`          | dano aplicado                       | impacto/soco |
| `heal.ogg`         | cura                                | chime/sino brilhante |
| `block.ogg`        | ganho de bloqueio                   | escudo/clangor curto |
| `button_click.ogg` | clique de botão de menu             | UI click |
| `button_hover.ogg` | (opcional) foco/hover de botão      | UI tick suave |
| `victory.ogg`      | vitória                             | fanfarra curta |
| `defeat.ogg`       | derrota                             | sting triste |
| `error.ogg`        | jogada recusada (energia insuf.)    | buzzer curto |

### Por tipo de carta (fallback quando a carta não define `sfx` no card_db)
| Arquivo             | Tipo    | Sugestão |
|---------------------|---------|----------|
| `card_attack.ogg`   | Ataque  | whoosh de lâmina/impacto |
| `card_defense.ogg`  | Defesa  | clangor metálico de escudo |
| `card_cure.ogg`     | Cura    | chime/sino suave |
| `card_buff.ogg`     | Buff    | power-up ascendente |
| `card_debuff.ogg`   | Debuff  | tom grave/sombrio (serve pros venenos) |
| `card_energy.ogg`   | Energia | moeda/zap elétrico |

### Overrides de cartas especiais (opcional)
Cartas "diferentonas" podem apontar uma chave própria em `Scripts/card_db.gd`
(campo `"sfx"`). Exemplos já ligados:
| Arquivo              | Carta            |
|----------------------|------------------|
| `card_fireball.ogg`  | Bola de Fogo     |
| `card_bender.ogg`    | Bebedeira Total  |

Para adicionar mais: crie o `.ogg`, registre a chave em `SFX_PATHS`
(audio_manager.gd) e coloque `"sfx": "sua_chave"` na carta em `card_db.gd`.

## Fontes grátis recomendadas
- **Kenney.nl** (CC0, sem atribuição): *Interface Sounds* (botões/erro),
  *Impact Sounds* / *RPG Audio* (ataque/hit/bloqueio), *Casino Audio*
  (moeda/energia — combina com o tema de aposta). Melhor ponto de partida.
- **OpenGameArt.org**: buscar "tavern loop", "battle loop", "magic", "heal", "shield".
- **freesound.org**: sons pontuais (filtrar por licença CC0).
- **incompetech.com** (Kevin MacLeod): música de taverna/combate (exige atribuição).
