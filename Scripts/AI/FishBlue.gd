extends Brain

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.alive:
    return
  
  if !owner.frozen:
    owner.velocity.x = owner.vars["speed"] * owner.dir
  else:
    owner.velocity.x = 0
    
  if owner.is_on_wall():
    owner.turn()
    
  if on_mario_collide('InsideDetector') and !owner.frozen:
    Global._ppd()
