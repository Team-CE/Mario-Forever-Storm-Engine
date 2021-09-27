extends Brain

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  owner.velocity.x = owner.vars["speed"] * owner.dir
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  if owner.is_on_wall():
    owner.turn()
    
  if is_mario_collide('BottomDetector'):
    owner.kill()
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.y_speed = -(owner.vars["bounce"] + 5)
    else:
      Global.Mario.y_speed = -owner.vars["bounce"]
  elif is_mario_collide('InsideDetector'):
    Global.Mario.kill()
