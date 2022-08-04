extends Brain

var counter: float = 0

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.NONE

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive or owner.frozen:
    return
    
  counter += 0.03 * Global.get_delta(delta)
  
  owner.velocity.x = cos(counter) * 150 * owner.dir
  if owner.is_on_wall():
    owner.turn()
  if on_mario_collide('InsideDetector'):
    Global._ppd()
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in range(len(g_overlaps)):
    if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
