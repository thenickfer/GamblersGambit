extends Node2D

func _ready() -> void:
	_refresh_label()

func _process(_delta: float) -> void:
	_refresh_label()

func draw_card() -> void:
	$"..".draw_player_card()
	_refresh_label()

func _refresh_label() -> void:
	var remaining = $"../PlayerStats".deck.size()
	$RichTextLabel.text = str(remaining)
	var empty = remaining == 0
	$Area2D/CollisionShape2D.disabled = empty
	$Sprite2D.visible = not empty
	$RichTextLabel.visible = not empty
