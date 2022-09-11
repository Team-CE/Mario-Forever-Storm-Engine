var hammer_scene = preload('res://Objects/Projectiles/Silver Hammer.tscn')

func throw(ai) -> void:
	var inst = hammer_scene.instance()
	inst.position = ai.owner.position - Vector2(0, 16).rotated(ai.owner.rotation)
	inst.belongs = 1
	inst.velocity.x *= (-1 if ai.owner.animated_sprite.flip_h else 1) * rand_range(1, 4) / 3
	inst.velocity.y *= rand_range(2, 4) / 3
	
	ai.owner.get_parent().add_child(inst)
