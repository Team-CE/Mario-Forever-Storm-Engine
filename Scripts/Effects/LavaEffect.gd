extends AnimatedSprite

func _init(pos: Vector2 = Vector2.ZERO, rot: float = 0):
	frames = preload('res://Prefabs/Effects/LavaEffect.tres')
	position = pos
	rotation = rot
	modulate.r = 1.2
	modulate.g = 1.2
	modulate.b = 1.2
	z_index = 6
	play('default')

func _process(_delta) -> void:
	if frame == 11:
		queue_free()
