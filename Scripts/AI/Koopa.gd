extends Brain

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.vars["stopped"]:
    owner.velocity.x = owner.vars["speed"] if !owner.vars["is shell"] else 0 if owner.vars["stopped"] else owner.vars["shell speed"] * owner.dir
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  if owner.is_on_wall():
    owner.turn()
    
    #when mario jumps on top
  if is_mario_collide('BottomDetector'):
    if owner.vars["stopped"]:  #Rework
      owner.dir = 1 if owner.position.x > Global.Mario.position.x else -1
      owner.vars["stopped"] = false
      owner.animated_sprite.animation = 'Shell Moving'
    else:
      owner.vars["stopped"] = true
      owner.animated_sprite.animation = 'Shell Stopped'
      
    if !owner.vars["is shell"]:
      owner.get_node("Collision").shape.extents.x += 2
      owner.vars["is shell"] = true
      owner.vars["stopped"] = true
      owner.animated_sprite.animation = 'Shell Stopped'
      
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.y_speed = -(owner.vars["bounce"] + 5)
    else:
      Global.Mario.y_speed = -owner.vars["bounce"]
    
  elif is_mario_collide('InsideDetector'):
    Global.Mario.kill()
