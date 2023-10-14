extends Area2D

var rng = RandomNumberGenerator.new()
var type = 0
var velocity: Vector2

func _ready() -> void:
	if type == 2:
		modulate.a = 0.0
		velocity.y = 2
	elif type == 1:
		velocity.y = rand_range(-2, -7.5)
		z_index = -49
	elif type == 0:
		rng.randomize()
		yield(get_tree(), 'physics_frame')
		if !is_in_water():
			queue_free()
	
func _physics_process(delta) -> void:
	if $AnimatedSprite.animation == 'disappear':
		if $AnimatedSprite.frame > 6:
			queue_free()
		return
	
	if type == 0:
		position.y -= rng.randf_range(0, 3) * Global.get_delta(delta)
		position.x += rng.randf_range(-2, 2) * Global.get_delta(delta)
	
	elif type == 1:
		if !Global.is_getting_closer(-32, global_position):
			queue_free()
		position += velocity * Global.get_delta(delta)

	elif type == 2:
		if !Global.is_getting_closer(-256, global_position):
			queue_free()
		if global_position.y >= Global.current_camera.limit_bottom + 8:
			queue_free()
		position += velocity * Global.get_delta(delta)

		if modulate.a < 1.0:
			modulate.a += 0.02 * Global.get_delta(delta)
		else:
			modulate.a = 1.0

func is_in_water() -> bool:
	for c in get_overlapping_areas():
		if c.is_in_group('Water'):
			return true
	return false

func _on_area_exited(area) -> void:
	if area.is_in_group('Water') and type == 0:
		$AnimatedSprite.play('disappear')
