class_name HammerThrow

var hammer_scene = preload('res://Objects/Projectiles/Hammer.tscn')

func throw(ai) -> void:
  var inst = hammer_scene.instance()
  inst.position = ai.owner.position - Vector2(0, 32)
  inst.belongs = 1
  inst.velocity.x *= (-1 if ai.owner.animated_sprite.flip_h else 1) * rand_range(1, 4) / 4
  inst.velocity.y *= rand_range(2, 4) / 4
  
  ai.owner.get_parent().add_child(inst)
