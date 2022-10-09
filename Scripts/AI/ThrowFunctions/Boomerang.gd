var hammer_scene = preload('res://Objects/Projectiles/Boomerang.tscn')

func throw(ai, vel_y: float = rand_range(0.6, 1)) -> void:
	var inst = hammer_scene.instance()
	inst.position = ai.owner.position - Vector2(0, 32).rotated(ai.owner.rotation)
	inst.belongs = 1
	inst.dir = (-1 if ai.owner.animated_sprite.flip_h else 1)
	inst.emalpka_owner = ai.get_instance_id()
	
	ai.owner.get_parent().add_child(inst)
