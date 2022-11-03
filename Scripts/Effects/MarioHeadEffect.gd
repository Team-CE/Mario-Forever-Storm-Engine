extends Sprite
class_name MarioHeadEffect

func _init(pos: Vector2 = Vector2.ZERO):
	texture = preload('res://GFX/Menu/Cursor.png')
	position = pos

func _physics_process(delta) -> void:
	modulate.a -= 0.05 * Global.get_delta(delta)
	if modulate.a <= 0:
		queue_free()
