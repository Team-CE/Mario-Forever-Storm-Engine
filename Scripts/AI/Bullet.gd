extends Brain

func _setup(b)-> void:
  ._setup(b)
  owner.get_node(owner.vars['hitbox']).connect('area_entered',self,"_on_hitbox_enter")

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  if !owner.alive:
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  else:
    owner.velocity.x = owner.vars["speed"] * owner.dir

func _on_hitbox_enter(a) -> void:
  if !owner.alive:
    return
  if a.name == 'InsideDetector':
    Global.Mario.kill()
  elif a.name == 'BottomDetector':
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.y_speed = -(owner.vars['bounce'] + 5)
    else:
      Global.Mario.y_speed = -owner.vars['bounce']
    owner.kill(AliveObject.DEATH_TYPE.FALL)
