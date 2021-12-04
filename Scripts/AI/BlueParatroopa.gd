extends Brain


func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.NONE

func _setup(b)-> void:
  ._setup(b)
  owner.get_node(owner.vars['kill zone']).connect('body_entered',self,"_on_kill_zone_enter")

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    
  if owner.is_on_floor():
    owner.velocity.y = -550
  
  if !owner.alive:
    return
  
  owner.velocity.x = (owner.vars['speed'] if !owner.vars['is shell'] else 0 if owner.vars['stopped'] else owner.vars['shell speed']) * owner.dir
  
  if owner.is_on_wall():
    owner.turn()
    
  if on_mario_collide('BottomDetector') and Global.Mario.velocity.y > 0: 
    owner.kill(AliveObject.DEATH_TYPE.CUSTOM, 0)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50
  elif is_mario_collide('InsideDetector') && !is_mario_collide('BottomDetector'):
    Global._ppd()
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in range(len(g_overlaps)):
    if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)

func _on_custom_death():
  owner.sound.play()
  owner.get_parent().add_child(ScoreText.new(owner.score, owner.position))
  var koopa = load('res://Objects/Enemies/Koopas/Koopa Blue.tscn').instance()
  koopa.position = owner.position
  owner.get_parent().add_child(koopa)
  owner.velocity_enabled = false
  owner.visible = false
  yield(get_tree().create_timer(0.5), 'timeout')
  owner.queue_free()
