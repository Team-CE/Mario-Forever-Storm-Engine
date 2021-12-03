extends Brain

var counter: float = 0
var move_multiplier: int = 1
var throw_activated: bool = false

var initial_pos: Vector2

var inited_throwable

func _ready_mixin() -> void:
  owner.death_type = AliveObject.DEATH_TYPE.FALL
  
func _setup(b) -> void:
  ._setup(b)
  initial_pos = owner.position
  inited_throwable = owner.vars['throw_script'].new()

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    return
    
  owner.velocity.x = owner.vars["speed"] * owner.dir * move_multiplier
  owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
  
  if counter < 20:
    counter += 1 * Global.get_delta(delta)
  else:
    counter = 0
    move_multiplier = round(rand_range(-4, 14) / 10)
    if rand_range(1, 14) > 13 and owner.is_on_floor():
      owner.velocity.y = -400
      
    var throw_was_activated: bool = false
      
    if throw_activated:
      owner.animated_sprite.animation = 'walk'
      owner.get_node('Throw').play()
      throw_was_activated = true
      throw_activated = false
      inited_throwable.throw(self)
      
    if rand_range(1, 14) > 9 and !throw_was_activated:
      throw_activated = true
      owner.animated_sprite.animation = 'holding'
      
  if abs((initial_pos - owner.position).x) > 70:
    owner.turn()
    
  owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
  
  if is_mario_collide('BottomDetector'):
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0, owner.sound)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50
  if on_mario_collide('InsideDetector'):
    Global._ppd()
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in range(len(g_overlaps)):
    if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
  
  
