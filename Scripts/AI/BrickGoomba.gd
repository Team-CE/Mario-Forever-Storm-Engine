extends Brain


var moving: int = 0
var preparing: bool = false
var counter: float = 0

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    return
  
  owner.velocity.x = owner.vars["speed"] * owner.dir * moving
  if owner.is_on_wall():
    owner.turn()
    
  if moving == 0 and !preparing:
    owner.animated_sprite.playing = false
    owner.animated_sprite.frame = 0
    
  if owner.is_on_floor() and moving == 1:
    moving = 0
    preparing = false
    counter = 40
    owner.animated_sprite.playing = false
    owner.animated_sprite.frame = 0
    owner.animated_sprite.speed_scale = 1
    owner.get_node('Stun').play()
    
  if counter > 0:
    counter -= 1 * Global.get_delta(delta)
   
  if preparing:
    owner.animated_sprite.playing = true
    if owner.animated_sprite.frame == 18:
      preparing = false
      moving = 1
      owner.velocity.y = -400
      owner.animated_sprite.frame = 5
      owner.animated_sprite.speed_scale = 0.5
      owner.dir = 1 if Global.Mario.position.x > owner.position.x else -1
      
  if moving == 1 and owner.animated_sprite.frame == 18:
    owner.animated_sprite.playing = false
      
  if Global.Mario.position.x > owner.position.x - 80 and Global.Mario.position.x < owner.position.x + 80 and !preparing and moving == 0 and counter <= 0:
    preparing = true

  if is_mario_collide('BottomDetector'):
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50
  elif on_mario_collide('InsideDetector'):
    Global._ppd()
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in range(len(g_overlaps)):
    if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
      
  owner.animated_sprite.flip_h = false

func _on_any_death():
  owner.sound.play()
  var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
  for i in range(4):
    var debris_effect = BrickEffect.new(owner.position + Vector2(0, -16), speeds[i])
    owner.get_parent().add_child(debris_effect)
