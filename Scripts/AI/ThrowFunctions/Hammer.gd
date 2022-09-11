var hammer_scene = preload('res://Objects/Projectiles/Hammer.tscn')

func throw(ai, vel_y: float = rand_range(0.6, 1)) -> void:
	var inst = hammer_scene.instance()
	inst.position = ai.owner.position - Vector2(0, 32).rotated(ai.owner.rotation)
	inst.belongs = 1
	inst.velocity.x *= (-1 if ai.owner.animated_sprite.flip_h else 1) * rand_range(0.2, 1)
	inst.velocity.y *= vel_y
	
	ai.owner.get_parent().add_child(inst)
