extends Sprite
class_name SawTrail

var counter: float = 0

func _init(pos: Vector2 = Vector2.ZERO, r: float = 0):
	texture = preload('res://GFX/Enemies/chainsaw.png')
	rotation_degrees = r
	position = pos

func _physics_process(delta) -> void:
	counter += 3 * Global.get_delta(delta)
	modulate.a = 1 - counter / 100.0
	
	if counter >= 100:
		queue_free()
