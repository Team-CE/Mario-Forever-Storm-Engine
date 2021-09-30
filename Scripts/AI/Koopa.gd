extends Brain

var shell_counter: float = 0

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.NONE

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  owner.velocity.x = owner.vars['speed'] if !owner.vars['is shell'] else 0 if owner.vars['stopped'] else owner.vars['shell speed'] * owner.dir
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  if owner.is_on_wall():
    owner.turn()

  if shell_counter < 31:
    shell_counter += 1 * Global.get_delta(delta)

  if on_mario_collide('BottomDetector'): 
    if !owner.vars['is shell']:
      owner.get_node('Collision').shape.extents.x += 2
      owner.vars['is shell'] = true
      owner.vars['stopped'] = true
      owner.animated_sprite.animation = 'Shell Stopped'

      owner.sound.play()
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.y_speed = -(owner.vars['bounce'] + 5)
      else:
        Global.Mario.y_speed = -owner.vars['bounce']
    elif owner.vars['is shell'] && !owner.vars['stopped']:
      owner.vars['stopped'] = true
      owner.animated_sprite.animation = 'Shell Stopped'

      owner.sound.play()
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.y_speed = -(owner.vars['bounce'] + 5)
      else:
        Global.Mario.y_speed = -owner.vars['bounce']

  if on_mario_collide('InsideDetector'):
    if owner.vars['stopped'] && owner.vars['is shell']:
      owner.vars['stopped'] = false
      owner.animated_sprite.animation = 'Shell Moving'
      owner.alt_sound.play()
      shell_counter = 0
      owner.dir = -1 if Global.Mario.position.x > owner.position.x else 1
    
  if is_mario_collide('InsideDetector') && !is_mario_collide('BottomDetector') && shell_counter >= 31:
    Global.Mario.kill()
