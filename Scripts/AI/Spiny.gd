extends Brain

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    return
  
  owner.velocity.x = owner.vars["speed"] * owner.dir
  if owner.is_on_wall():
    owner.turn()
    
  elif is_mario_collide('InsideDetector'):
    Global.Mario.kill()
