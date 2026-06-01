extends Node2D

# Marque como false nos slots onde o jogador NÃO pode jogar (ex.: slot do oponente).
@export var is_player_slot: bool = true
@export var drop_area_size: Vector2 = Vector2(170, 220)
@export var drop_area_offset: Vector2 = Vector2.ZERO

var card_in_slot = false
var card_node = null  # carta atualmente neste slot (descartada ao jogar outra)

@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	var drop_shape := RectangleShape2D.new()
	drop_shape.size = drop_area_size
	collision_shape.shape = drop_shape
	collision_shape.position = drop_area_offset

func get_card_snap_position() -> Vector2:
	return global_position
