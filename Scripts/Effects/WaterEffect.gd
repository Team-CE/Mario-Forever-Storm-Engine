extends AnimatedSprite

func _init(pos: Vector2 = Vector2.ZERO):
	frames = preload('res://Prefabs/Effects/WaterEffect.tres')
	position = pos
	z_index = 1
	play('default')

func _physics_process(_delta) -> void:
	if frame == 15:
		queue_free()
