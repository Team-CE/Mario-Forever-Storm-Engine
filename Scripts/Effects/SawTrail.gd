extends Sprite
class_name LuiTrail

var counter: float = 0

func _init(pos: Vector2 = Vector2.ZERO, flip: bool = false, r: float = 0):
	texture = preload('res://GFX/Mario/LuiJump.png')
	offset = Vector2(0, -28)
	flip_h = flip
	position = pos.rotated(-r)
	rotation = r

func _physics_process(delta) -> void:
	counter += 3 * Global.get_delta(delta)
	modulate.a = 1 - counter / 100.0
	
	if counter >= 100:
		queue_free()
