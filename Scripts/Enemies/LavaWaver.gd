extends Area2D

var motion_wave: float = 16
var dir_right: bool = false

func _process(delta):
	if dir_right:
		position.x += 2 * Global.get_delta(delta)
	else:
		position.x -= 2 * Global.get_delta(delta)
	if motion_wave <= 0:
		queue_free()
# Main waving events are in Scripts/Enemies/BowserLavaSpring.gd
