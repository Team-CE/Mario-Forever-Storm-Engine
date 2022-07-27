extends Brain

var inv_counter: float = 0

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
  
  if inv_counter < 7:
    inv_counter += 1 * Global.get_delta(delta)
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in g_overlaps:
    if 'triggered' in i and i.triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
  
  if inv_counter < 10:
    inv_counter += 1 * Global.get_delta(delta)
  if !Global.Mario.is_in_shoe:
    if on_mario_collide('InsideDetector') and !owner.frozen:
      Global._ppd()
  else:
    if is_mario_collide('BottomDetector') and !owner.frozen and Global.Mario.velocity.y > 0:
      inv_counter = 0
      Global.Mario.shoe_node.stomp()
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
      return
    elif on_mario_collide('InsideDetector') and !owner.frozen and inv_counter > 8:
      Global._ppd()
