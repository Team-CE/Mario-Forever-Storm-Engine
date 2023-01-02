extends Node2D

var touch_button_disabled :bool = false

func _physics_process(_delta):
	visible = !touch_button_disabled
	position = Vector2(get_viewport().size.x * (touch_button_disabled as int), 0)
