extends Node2D

signal on_cliff

func _on_body_exit(body : Node2D):
	if !body.is_in_group("Solid"):
		return
	emit_signal("on_cliff")
