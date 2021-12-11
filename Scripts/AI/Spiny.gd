extends Brain

func _ready_mixin() -> void:
  owner.death_type = AliveObject.DEATH_TYPE.NONE

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
  
  if owner.animated_sprite.frame == 5 and owner.animated_sprite.animation == 'appear':
    owner.animated_sprite.animation = 'walk'
    owner.animated_sprite.frame = 0
    
  if owner.is_on_wall() and !owner.frozen:
    owner.turn()
    
  if on_mario_collide('InsideDetector') and !owner.frozen:
    Global._ppd()

  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in range(len(g_overlaps)):
    if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
