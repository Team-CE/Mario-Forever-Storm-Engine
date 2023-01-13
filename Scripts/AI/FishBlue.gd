extends Brain

func _setup(b) -> void:
	._setup(b)
	if owner.dir == 1:
		owner.animated_sprite.flip_h = owner.dir < 0

func _ai_process(delta:float) -> void:
	._ai_process(delta)
	if !owner.alive:
		return
	
	if !owner.frozen:
		owner.velocity.x = owner.vars["speed"] * owner.dir
	else:
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
		owner.get_node('Collision2').disabled = false
		owner.get_node('Collision').disabled = true
		owner.gravity_scale = 0.5
		owner.invincible = false
		if !owner.is_on_floor():
			owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
		return
		
	if owner.is_on_wall():
		owner.turn()
		
	if on_mario_collide('InsideDetector'):
		Global._ppd()
