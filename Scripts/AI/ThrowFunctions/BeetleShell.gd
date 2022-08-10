var hammer_scene = preload('res://Objects/Projectiles/BeetleShell.tscn')

func throw(ai) -> void:
  var inst = hammer_scene.instance()
  inst.position = ai.owner.position - Vector2(0, 32).rotated(ai.owner.rotation)
  inst.belongs = 1
  inst.velocity.x *= (-1 if ai.owner.animated_sprite.flip_h else 1) * rand_range(0.4, 1)
  inst.velocity.y *= rand_range(0.6, 1)
  inst.parent = ai.owner.get_instance_id()
  inst.z_index = 1
  
  ai.owner.get_parent().add_child(inst)
