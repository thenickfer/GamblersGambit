extends Node

# Singleton de áudio (autoload "AudioManager"). Responsável por:
#   - música de fundo por cena, com crossfade e continuidade entre cenas que
#     pedem a mesma faixa (Título -> Menu não corta);
#   - efeitos sonoros pontuais, tocados por um pool de players para permitir
#     sons sobrepostos.
#
# É TOLERANTE A ARQUIVO AUSENTE: os streams são resolvidos em _ready() e, se um
# .ogg ainda não existe na pasta, o play_* correspondente simplesmente não
# toca (sem crash). Assim o jogo roda enquanto os assets são adicionados aos
# poucos. Por isso usamos load()/ResourceLoader.exists() e NÃO preload().

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

const MUSIC_VOLUME_DB := -6.0   # volume alvo da música quando tocando
const SFX_VOLUME_DB := 0.0
const CROSSFADE_TIME := 1.0     # segundos para trocar de faixa
const SILENT_DB := -60.0        # "mudo" prático para o fade

const SFX_POOL_SIZE := 8

# Chave lógica -> caminho do recurso. Resolvidos em _ready(); ausentes viram null.
const MUSIC_PATHS := {
	"menu":   "res://Assets/Audio/Music/menu_theme.ogg",
	"combat": "res://Assets/Audio/Music/combat_theme.ogg",
}

const SFX_PATHS := {
	# universais
	"card_draw":    "res://Assets/Audio/SFX/card_draw.ogg",
	"card_place":   "res://Assets/Audio/SFX/card_place.ogg",
	"hit":          "res://Assets/Audio/SFX/hit.ogg",
	"heal":         "res://Assets/Audio/SFX/heal.ogg",
	"block":        "res://Assets/Audio/SFX/block.ogg",
	"button_click": "res://Assets/Audio/SFX/button_click.ogg",
	"button_hover": "res://Assets/Audio/SFX/button_hover.ogg",
	"victory":      "res://Assets/Audio/SFX/victory.ogg",
	"defeat":       "res://Assets/Audio/SFX/defeat.ogg",
	"error":        "res://Assets/Audio/SFX/error.ogg",
	# por tipo de carta (fallback quando a carta não declara "sfx")
	"card_attack":  "res://Assets/Audio/SFX/card_attack.ogg",
	"card_defence": "res://Assets/Audio/SFX/card_defense.ogg",
	"card_cure":    "res://Assets/Audio/SFX/card_cure.ogg",
	"card_buff":    "res://Assets/Audio/SFX/card_buff.ogg",
	"card_debuff":  "res://Assets/Audio/SFX/card_debuff.ogg",
	"card_energy":  "res://Assets/Audio/SFX/card_energy.ogg",
	# overrides de cartas "diferentonas" (chave usada no card_db via "sfx")
	"card_fireball":"res://Assets/Audio/SFX/card_fireball.ogg",
	"card_bender":  "res://Assets/Audio/SFX/card_bender.ogg",
}

var _music_streams := {}   # key -> AudioStream (ou null)
var _sfx_streams := {}      # key -> AudioStream (ou null)

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _current_music_key := ""
var _music_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # segue tocando durante o pause (tela de fim)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_or_master(MUSIC_BUS)
	_music_player.volume_db = SILENT_DB
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	for _i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = _bus_or_master(SFX_BUS)
		p.volume_db = SFX_VOLUME_DB
		add_child(p)
		_sfx_players.append(p)

	for key in MUSIC_PATHS:
		var s = _try_load(MUSIC_PATHS[key])
		if s != null and "loop" in s:
			s.loop = true  # loop interno do Godot (sem emenda) p/ .ogg/.mp3
		_music_streams[key] = s
	for key in SFX_PATHS:
		_sfx_streams[key] = _try_load(SFX_PATHS[key])

func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) != -1 else "Master"

func _try_load(path: String):
	if ResourceLoader.exists(path):
		return load(path)
	# Tolera extensão diferente da esperada.
	var base := path.get_basename()
	for ext in [".ogg", ".mp3"]:
		var alt: String = base + ext
		if alt != path and ResourceLoader.exists(alt):
			return load(alt)
	return null

# Faz a faixa dar loop mesmo em formatos sem loop no import. Um .ogg com
# loop nunca chega aqui, então continua sem emenda.
func _on_music_finished() -> void:
	if _current_music_key != "" and _music_player.stream != null:
		_music_player.play()

# --- Música ---

# Toca a faixa da chave dada. Se já for a faixa atual, não faz nada (continuidade
# entre cenas). Se a faixa não existir, apenas silencia a atual.
func play_music(key: String) -> void:
	if key == _current_music_key:
		return
	_current_music_key = key
	var stream = _music_streams.get(key, null)
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	if stream == null:
		_music_player.stop()
		return
	if _music_player.playing:
		# crossfade: baixa a atual, troca o stream, sobe a nova
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", SILENT_DB, CROSSFADE_TIME * 0.5)
		_music_tween.tween_callback(func() -> void:
			_music_player.stream = stream
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", MUSIC_VOLUME_DB, CROSSFADE_TIME * 0.5)
	else:
		_music_player.stream = stream
		_music_player.volume_db = MUSIC_VOLUME_DB
		_music_player.play()

func stop_music() -> void:
	_current_music_key = ""
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_player.stop()

func fade_out_music(duration := CROSSFADE_TIME) -> void:
	_current_music_key = ""
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	if not _music_player.playing:
		return
	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music_player, "volume_db", SILENT_DB, duration)
	_music_tween.tween_callback(func() -> void:
		_music_player.stop()
		_music_player.volume_db = SILENT_DB
	)

# --- SFX ---

# Toca um efeito sonoro pela chave. Usa o pool em round-robin para permitir
# sobreposição. pitch_variation adiciona uma leve variação aleatória de tom.
func play_sfx(key: String, pitch_variation := 0.06) -> void:
	var stream = _sfx_streams.get(key, null)
	if stream == null:
		return
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()

# --- Volume (para um futuro menu de opções) ---

func set_music_volume(db: float) -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

func set_sfx_volume(db: float) -> void:
	var idx := AudioServer.get_bus_index(SFX_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)
