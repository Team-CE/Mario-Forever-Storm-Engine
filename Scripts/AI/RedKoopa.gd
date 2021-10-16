extends Brain

var shell_counter: float = 0
var score_mp:int

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.NONE

func _setup(b)-> void:
  ._setup(b)
  owner.get_node(owner.vars['kill zone']).connect('body_entered',self,"_on_kill_zone_enter")

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    return
  
  owner.velocity.x = (owner.vars['speed'] if !owner.vars['is shell'] else 0 if owner.vars['stopped'] else owner.vars['shell speed']) * owner.dir
  if owner.is_on_wall() || (owner.on_edge() && !owner.vars['is shell']):
    owner.turn()

  if shell_counter < 31:
    shell_counter += 1 * Global.get_delta(delta)
    
  if on_mario_collide('BottomDetector'): 
    if !owner.vars['is shell']:
      owner.get_parent().add_child(ScoreText.new(100, owner.position))
      owner.vars['is shell'] = true
      owner.get_node(owner.vars['kill zone']).get_child(0).disabled = false
      owner.vars['stopped'] = true
      owner.animated_sprite.animation = 'shell stopped'
    
      owner.sound.play()
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.velocity.y = -(owner.vars['bounce'] + 5) * 50
      else:
        Global.Mario.velocity.y = -owner.vars['bounce'] * 50
    elif owner.vars['is shell'] && !owner.vars['stopped']: #Stops the shell
      score_mp = 0
      owner.get_parent().add_child(ScoreText.new(100, owner.position))
      owner.vars['stopped'] = true
      owner.animated_sprite.animation = 'shell stopped'
    
      owner.sound.play()
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.velocity.y = -(owner.vars['bounce'] + 5) * 50
      else:
        Global.Mario.velocity.y = -owner.vars['bounce'] * 50
  
  if on_mario_collide('InsideDetector'):
    if owner.vars['stopped'] && owner.vars['is shell']:
      owner.vars['stopped'] = false
      owner.animated_sprite.animation = 'shell moving'
      owner.alt_sound.play()
      shell_counter = 0
      owner.dir = -1 if Global.Mario.position.x > owner.position.x else 1
    
  if is_mario_collide('InsideDetector') && !is_mario_collide('BottomDetector') && shell_counter >= 31:
    Global.Mario.kill()

func _on_kill_zone_enter(b:Node) -> void:
  if owner.vars['is shell'] && abs(owner.velocity.x) > 0 && b.is_class('KinematicBody2D') && b != owner:
    b.kill(AliveObject.DEATH_TYPE.FALL, score_mp)
    #AudioServer.get_bus_effect(1,0).pitch_scale = AliveObject.pitch_md[score_mp]
    #print(AudioServer.get_bus_effect(1,0).pitch_scale)
    if score_mp < 6:
      score_mp += 1
    else:
      score_mp = 0
