class_name FireballThrow

var hammer_scene = preload('res://Objects/Projectiles/Fireball.tscn')

func throw(ai) -> void:
  var inst = hammer_scene.instance()
  inst.position = ai.owner.position - Vector2(0, 24).rotated(ai.owner.rotation)
  inst.belongs = 2
  inst.dir = -1 if ai.owner.animated_sprite.flip_h else 1
  inst.velocity.y = ai.owner.velocity.y
  
  var children = ai.owner.get_parent().get_children()
  for node in range(len(children)):
    if children[node].get_name() == 'Fireball':
      ai.owner.add_collision_exception_with(children[node])
  
  ai.owner.get_parent().add_child(inst)
