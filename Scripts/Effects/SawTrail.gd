extends Sprite
class_name LuiTrail

var counter: float = 0

func _init(pos: Vector2 = Vector2.ZERO, flip: bool = false):
	texture = preload('res://GFX/Mario/LuiJump.png')
	flip_h = flip
	position = pos

func _physics_process(delta) -> void:
	counter += 3 * Global.get_delta(delta)
	modulate.a = 1 - counter / 100.0
	
	if counter >= 100:
		queue_free()
