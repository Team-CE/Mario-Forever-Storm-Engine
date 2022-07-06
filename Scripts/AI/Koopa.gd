extends Brain

var shell_counter: float = 0
var score_mp: int
var error: bool = false

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.NONE
  if owner.vars['is shell']:
# warning-ignore:standalone_ternary
    to_stopped_shell() if owner.vars['stopped'] else to_moving_shell()
  
  if not 'qblock zone' in owner.vars:
    printerr('ERROR: could not find qblock zone for enemy ' + owner.name + '! Please recreate the object')
    error = true
    
func _setup(b)-> void:
  ._setup(b)

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    owner.get_node(owner.vars['kill zone']).get_child(0).disabled = true
    if !error: owner.get_node(owner.vars['qblock zone']).get_child(0).disabled = true
    return
  
  if !owner.frozen:
    owner.velocity.x = (owner.vars['speed'] if !owner.vars['is shell'] else 0 if owner.vars['stopped'] else owner.vars['shell speed']) * owner.dir
  else:
    owner.velocity.x = 0
    if !owner.vars['is shell']:
      owner.get_node('Collision2').disabled = false
      owner.get_node('Collision').disabled = true
      owner.frozen_sprite.animation = 'medium'
      owner.frozen_sprite.position.y = -32
    return
  
  var turn_if_no_break: bool = true
    
  for b in owner.get_node(owner.vars['kill zone']).get_overlapping_bodies():
    if owner.vars['is shell'] && !owner.vars['stopped'] && abs(owner.velocity.x) > 0:
      if b.is_class('KinematicBody2D') && b != owner && b.has_method('kill'): #&& Global.is_getting_closer(-32, owner.position):
        if 'is shell' in b.vars and 'stopped' in b.vars and !b.vars['stopped'] and b.vars['is shell']:
          owner.kill(AliveObject.DEATH_TYPE.FALL, 0, null, null, true)
          b.kill(AliveObject.DEATH_TYPE.FALL, 0, null, null, true)
          return
        b.kill(AliveObject.DEATH_TYPE.FALL, score_mp, null, null, true)
        if score_mp < 6:
          score_mp += 1
        else:
          score_mp = 0

  if !error: for b in owner.get_node_or_null(owner.vars['qblock zone']).get_overlapping_bodies():
    if owner.vars['is shell'] && !owner.vars['stopped'] && abs(owner.velocity.x) > 0:
      if b is QBlock and b.active:
        b.hit(1, true)
        owner.turn()
        turn_if_no_break = false
  
  if owner.is_on_wall() and turn_if_no_break:
    owner.turn()

  if shell_counter < 41:
    shell_counter += 1 * Global.get_delta(delta)
    
  if is_mario_collide('BottomDetector') and Global.Mario.velocity.y > 0 && shell_counter >= 11: 
    if !owner.vars['is shell']:
      owner.get_parent().add_child(ScoreText.new(100, owner.position))
      to_stopped_shell()
    
      owner.sound.play()
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.velocity.y = -(owner.vars['bounce'] + 5) * 50
      else:
        Global.Mario.velocity.y = -owner.vars['bounce'] * 50
    elif owner.vars['is shell'] && !owner.vars['stopped']: #Stops the shell
      owner.get_parent().add_child(ScoreText.new(100, owner.position))
      to_stopped_shell()
    
      owner.sound.play()
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.velocity.y = -(owner.vars['bounce'] + 5) * 50
      else:
        Global.Mario.velocity.y = -owner.vars['bounce'] * 50
  elif is_mario_collide('InsideDetector') and !owner.vars['stopped'] and shell_counter >= 31:
    Global._ppd()
    
  if is_mario_collide('InsideDetector'):
    if owner.vars['stopped'] && owner.vars['is shell'] && shell_counter >= 11:
      to_moving_shell()
      owner.dir = -1 if Global.Mario.position.x > owner.position.x else 1
      owner.alt_sound.pitch_scale = 0.9
      owner.alt_sound.play()
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in range(len(g_overlaps)):
    if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)

func to_stopped_shell() -> void:
  owner.get_node(owner.vars['kill zone']).get_child(0).disabled = false
  if !error: owner.get_node(owner.vars['qblock zone']).get_child(0).disabled = false
  shell_counter = 0
  owner.vars['is shell'] = true
  score_mp = 0
  owner.vars['stopped'] = true
  owner.animated_sprite.animation = 'shell stopped'
  if 'visibility_enabler' in owner.vars:
    owner.get_node(owner.vars['visibility_enabler']).rect = Rect2( -16, -32, 32, 32 )
  else:
    print('ERROR: could not find visibility_enabler for ' + owner.name)
  if !owner.death_signal_exception: owner.emit_signal('enemy_died')

func to_moving_shell() -> void:
  owner.vars['is shell'] = true
  owner.vars['stopped'] = false
  owner.animated_sprite.animation = 'shell moving'
  if 'visibility_enabler' in owner.vars:
    owner.get_node(owner.vars['visibility_enabler']).rect = Rect2( -480, -192, 960, 320 )
  else:
    print('ERROR: could not find visibility_enabler for ' + owner.name)
  shell_counter = 0
