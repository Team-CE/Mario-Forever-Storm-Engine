extends Brain

var piranha_counter: float = 0
var initial_pos: Vector2
var offset_pos: Vector2 = Vector2.ZERO

var shooting: bool = false
var projectile_counter: int = 0
var projectile_timer: float = 0

var rng = RandomNumberGenerator.new()

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.DISAPPEAR
  owner.velocity_enabled = false
  initial_pos = owner.position
  owner.get_node('Placeholder1').queue_free()
  owner.get_node('Placeholder2').queue_free()
  owner.get_node('Placeholder3').queue_free()
  
  if owner.vars['type'] == 1:
    owner.animated_sprite.frames = load('res://Prefabs/Piranhas/Fire.tres')
  else:
    owner.get_node('Light2D').queue_free()
    
  var children = owner.get_parent().get_children()
  for node in range(len(children)):
    if 'AI' in children[node]:
      owner.add_collision_exception_with(children[node])
  
func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !owner.alive:
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    owner.velocity_enabled = true
    return

  if on_mario_collide('InsideDetector'):
    Global._ppd()
    
  if projectile_timer > 0:
    projectile_timer -= 1 * Global.get_delta(delta)

  piranha_counter += 1 * Global.get_delta(delta)
  
  if piranha_counter == 0:
    offset_pos = Vector2.ZERO

  if piranha_counter < 64:
    offset_pos += Vector2(0, -1).rotated(owner.rotation) * Global.get_delta(delta)
    
  if piranha_counter > 64 and piranha_counter < 66:
    shooting = true
  
  if owner.vars['type'] > 0:
    _process_shooting(delta)
  
  if piranha_counter >= 130 and piranha_counter < 194:
    offset_pos += Vector2(0, 1).rotated(owner.rotation) * Global.get_delta(delta)
  
  if piranha_counter >= 260 and (Global.Mario.position.x < owner.position.x - 80 or Global.Mario.position.x > owner.position.x + 80):
    piranha_counter = 0
    
  owner.position = initial_pos + offset_pos
  
func _process_shooting(delta: float):
  if projectile_timer <= 0 and projectile_counter < owner.vars['projectile count'] and shooting:
    owner.sound.play()
    projectile_timer = 10
    projectile_counter += 1
    var fireball = load('res://Objects/Projectiles/Fireball.tscn').instance()
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

