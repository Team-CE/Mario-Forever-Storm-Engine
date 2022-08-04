extends Brain

var piranha_counter: float = 0
var initial_pos: Vector2
var offset_pos: Vector2 = Vector2.ZERO

var shooting: bool = false
var projectile_counter: int = 0
var projectile_timer: float = 0
var fireball

var rng = RandomNumberGenerator.new()

var rotat: float
var inv_counter: float = 10

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.DISAPPEAR
  owner.velocity_enabled = false
  initial_pos = owner.position
  owner.get_node('Placeholder1').queue_free()
  owner.get_node('Placeholder2').queue_free()
  owner.get_node('Placeholder3').queue_free()
  rng.randomize()
  
  if owner.vars['type'] == 1:
    owner.animated_sprite.frames = preload('res://Prefabs/Piranhas/Fire.tres')
    owner.get_node('Light2D').visible = true
  elif owner.vars['type'] == 2:
    owner.animated_sprite.frames = preload('res://Prefabs/Piranhas/Ice.tres')
    owner.get_node('Light2D').visible = true
  else:
    owner.get_node('Light2D').queue_free()
    
  var children = owner.get_parent().get_children()
  for node in children:
    if 'AI' in node:
      owner.add_collision_exception_with(node)
  
func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !owner.alive or owner.frozen:
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    owner.velocity_enabled = true
    
    if owner.frozen:
      owner.get_node('Collision2').disabled = false
      owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
    else:
      owner.animated_sprite.rotation = rotat
    return

  rotat = owner.rotation

  if !Global.Mario.is_in_shoe:
    if on_mario_collide('InsideDetector'):
      Global._ppd()
  else:
    if is_mario_collide('BottomDetector'):
      inv_counter = 0
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
      Global.Mario.shoe_node.stomp()
      owner.velocity.y = 0
    elif on_mario_collide('InsideDetector') and inv_counter > 8:
      Global._ppd()
  
  if inv_counter < 10:
    inv_counter += 1 * Global.get_delta(delta)
    
  if projectile_timer > 0:
    projectile_timer -= 1 * Global.get_delta(delta)

  piranha_counter += 1 * Global.get_delta(delta)
  
  if piranha_counter == 0:
    offset_pos = Vector2.ZERO

  if piranha_counter < 64:
    offset_pos += Vector2(0, -1).rotated(owner.rotation) * Global.get_delta(delta)
    
  if piranha_counter >= 64 and piranha_counter <= 66:
    shooting = true
  
  if owner.vars['type'] > 0:
    _process_shooting(delta)
  
  if piranha_counter >= 130 and piranha_counter < 193:
    offset_pos += Vector2(0, 1).rotated(owner.rotation) * Global.get_delta(delta)
  
  if piranha_counter >= 260 and (Global.Mario.position.x < owner.position.x - 80 or Global.Mario.position.x > owner.position.x + 80):
    piranha_counter = 0
    
  owner.position = initial_pos + offset_pos
  
func _process_shooting(_delta):
  if projectile_timer <= 0 and projectile_counter < owner.vars['projectile count'] and shooting:
    owner.sound.play()
    projectile_timer = owner.vars['shoot interval'] if 'shoot interval' in owner.vars else 10
    projectile_counter += 1
    if ('no fireballs above screen' in owner.vars and owner.vars['no fireballs above screen']
    and owner.position.y + 272 < Global.Mario.position.y):
      return
    if owner.vars['type'] == 2:
      fireball = preload('res://Objects/Projectiles/Iceball.tscn').instance()
    else:
      fireball = preload('res://Objects/Projectiles/Fireball.tscn').instance()
    fireball.velocity = Vector2(rng.randf_range(-200.0, 200.0), rng.randf_range(-70, -600)).rotated(owner.rotation)
    fireball.position = owner.position + Vector2(0, -32).rotated(owner.rotation)
    fireball.belongs = 1
    fireball.gravity_scale = 0.5
    fireball.z_index = 1
    owner.get_parent().add_child(fireball)

  if projectile_counter >= owner.vars['projectile count']:
    shooting = false
    projectile_counter = 0
    projectile_timer = 0

