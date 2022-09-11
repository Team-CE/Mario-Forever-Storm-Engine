extends Area2D

var velocity: Vector2
var timer: float = 0

func _ready():
	pass

func _process(delta):
	if Global.is_mario_collide_area('InsideDetector', self):
		Global._ppd()
	
	position += velocity * Global.get_delta(delta)
	velocity.y += 0.2 * Global.get_delta(delta)
	$Sprite.rotation_degrees += 12 + rand_range(0, 8) * Global.get_delta(delta)
	
	if position.y > 512:
		queue_free()
	
	if timer < 5:
		timer += 1 * Global.get_delta(delta)
	else:
		z_index = 1
