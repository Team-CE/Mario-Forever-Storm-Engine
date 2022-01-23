extends Brain

var top: bool = false
var falling: bool = false

var counter: float = 50
var hit_counter: float = 0

var initial_pos: Vector2
var offset: Vector2

func _setup(b) -> void:
  ._setup(b)
  initial_pos = owner.position

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor() and falling:
    owner.velocity += Vector2(0, 40 * owner.gravity_scale * Global.get_delta(delta))

  if Global.is_mario_collide_area('InsideDetector', owner.get_node('Hitbox')):
    Global._ppd()
    
  if !falling and !top:
    owner.velocity = Vector2.ZERO

  if falling:
    counter = 50
    var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
    for i in range(len(g_overlaps)):
      if g_overlaps[i].has_method('hit'):
        if ('ignore hidden' in owner.vars and owner.vars['ignore hidden']) && !g_overlaps[i].visible: return
        g_overlaps[i].hit(delta, true)
        if g_overlaps[i].qtype == QBlock.BLOCK_TYPE.BRICK:
          hit_counter = 3
        
  if hit_counter > 0:
    hit_counter -= 1 * Global.get_delta(delta)
    Global.Mario.get_node('Camera').set_offset(Vector2(
      rand_range(-3.0, 3.0),
      rand_range(-3.0, 3.0)
    ))
    
  if hit_counter <= 0 and hit_counter > -99:
    Global.Mario.get_node('Camera').set_offset(Vector2(0, 0))
    hit_counter = -99

  var area_overlaps = owner.get_node('Area2D').get_overlapping_bodies()
  if area_overlaps.has(Global.Mario) and !falling and !top:
    falling = true
    
  if owner.is_on_floor() and falling:
    owner.sound.play()
    owner.get_parent().add_child(Explosion.new(owner.position + owner.get_node('EffectPosition1').position))
    owner.get_parent().add_child(Explosion.new(owner.position + owner.get_node('EffectPosition2').position))
    if hit_counter <= 0:
      falling = false
      top = true
    else:
      owner.velocity = Vector2(0, 10)
    
  if top:
    owner.velocity = Vector2.ZERO
    if counter == 50:
      hit_counter = 20
      offset = (owner.position - initial_pos).rotated(-owner.rotation)
      owner.get_node('CollisionShape2D').disabled = true
      
    if counter > 0:
      counter -= 1 * Global.get_delta(delta)
      owner.position = initial_pos + offset.rotated(owner.rotation)
    
    if counter <= 0:
      if offset.y > 0:
        offset += Vector2(0, -1) * Global.get_delta(delta)
        owner.position = initial_pos + offset.rotated(owner.rotation)
      else:
        owner.position = initial_pos
        top = false
        falling = false
        owner.get_node('CollisionShape2D').disabled = false
        
        
  if owner.animated_sprite.frame == 7:
    owner.animated_sprite.playing = false
    
  if rand_range(-70.0, 40.0) > 39.0:
    owner.animated_sprite.frame = 0
    owner.animated_sprite.playing = true
