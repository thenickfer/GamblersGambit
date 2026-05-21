extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




# card.gd (attached to Area2D)
#extends Area2D
#
#func _ready():
	#mouse_entered.connect(_on_mouse_entered)
	#mouse_exited.connect(_on_mouse_exited)
	#input_event.connect(_on_input_event)
#
#func _on_mouse_entered():
	#create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
#
#func _on_mouse_exited():
	#create_tween().tween_property(self, "scale", Vector2(1, 1), 0.2)
#
#func _on_input_event(event):
	#if event is InputEventMouseButton and event.pressed:
		#print("Clicou na carta!")
