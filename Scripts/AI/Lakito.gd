extends Brain

var counter: int = 0

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    return
  
  if !owner.frozen:
    owner.velocity.x = owner.vars["speed"] * owner.dir
  else:
    owner.velocity.x = 0
    
  if is_mario_collide('BottomDetector') and !owner.frozen and Global.Mario.velocity.y > 0:
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50

func _physics_process(delta: float) -> void:
  pass
