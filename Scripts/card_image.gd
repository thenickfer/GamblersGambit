extends Node2D

@export var base_texture: Texture2D:
	set(value):
		base_texture = value
		_apply_textures()

@export var art_texture: Texture2D:
	set(value):
		art_texture = value
		_apply_textures()

@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
		_apply_textures()

@export var auto_fit_art: bool = false:
	set(value):
		auto_fit_art = value
		_apply_art_layout()

@export var art_offset: Vector2 = Vector2(0, -42):
	set(value):
		art_offset = value
		_apply_art_layout()

@export var art_size: Vector2 = Vector2(170, 96):
	set(value):
		art_size = value
		_apply_art_layout()

@onready var base_image: Sprite2D = $BaseImage
@onready var art_image: Sprite2D = $ArtImage
@onready var frame_image: Sprite2D = $FrameImage
@onready var card_name: Label = $Nome
@onready var card_value: Label = $Valor
@onready var card_turns: Label = $Turnos
@onready var card_type: Label = $Tipo


func _ready() -> void:
	_apply_textures()
	_apply_art_layout()


func set_art_from_path(texture_path: String) -> void:
	if texture_path.is_empty():
		push_warning("Card art texture path is empty.")
		set_art_texture(null)
		return
	if not ResourceLoader.exists(texture_path):
		push_warning("Card art texture does not exist: " + texture_path)
		set_art_texture(null)
		return

	var texture: Texture2D = ResourceLoader.load(texture_path, "Texture2D") as Texture2D
	if texture == null:
		push_warning("Card art resource is not a Texture2D: " + texture_path)
	set_art_texture(texture)


	
func set_nome(name: String) -> void:
	card_name.text = name
	
func set_value(val: int) -> void:
	card_value.text = "VALOR: " + str(val)
	
func set_turns(val: int) -> void:
	card_turns.text = "TURNOS: " + str(val)
	
func set_type(action: String) -> void:
	card_type.text = action
	
func set_art_texture(texture: Texture2D) -> void:
	art_texture = texture


func _apply_textures() -> void:
	if not is_node_ready():
		return
	base_image.texture = base_texture
	art_image.texture = art_texture
	frame_image.texture = frame_texture
	_apply_art_layout()


func _apply_art_layout() -> void:
	if not is_node_ready():
		return

	art_image.visible = art_image.texture != null
	if art_image.texture == null:
		return
	if not auto_fit_art:
		return

	art_image.position = art_offset

	var source_size: Vector2 = _get_art_source_size()
	if source_size.x <= 0 or source_size.y <= 0:
		art_image.scale = Vector2.ONE
		return

	var fit_scale: float = minf(art_size.x / source_size.x, art_size.y / source_size.y)
	art_image.scale = Vector2(fit_scale, fit_scale)


func _get_art_source_size() -> Vector2:
	if art_image.region_enabled:
		return art_image.region_rect.size
	return art_image.texture.get_size()
