extends AnimatedSprite

var counter = 0

func _process(delta):
	counter += 1 * Global.get_delta(delta)
	if counter < 40:
		position.y -= 1 * Global.get_delta(delta)
	if counter > 120:
		queue_free()
