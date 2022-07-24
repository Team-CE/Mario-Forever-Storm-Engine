extends Brain

var speed_modifier: float = 0
var speed: float = 200
const speed_cap: int = 200
var temp: bool = false
var old_rotation: float = 0
var inv_counter: float = 0

func _setup(b)-> void:
  ._setup(b)
# warning-ignore:return_value_discarded
  owner.get_node(owner.vars['hitbox']).connect('area_entered',self,"_on_hitbox_enter")
  owner.animated_sprite.flip_v = owner.rotation > 0.5

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  if owner.velocity.y < 0:
    owner.velocity.y = 0
  # Animation
  owner.animated_sprite.modulate.r += 0.15 * Global.get_delta(delta)
  owner.animated_sprite.modulate.g -= 0.15 * Global.get_delta(delta)
  owner.animated_sprite.modulate.b -= 0.15 * Global.get_delta(delta)
  if owner.animated_sprite.modulate.r > 1.5:
    owner.animated_sprite.modulate = Color.white
  
  if !Global.is_getting_closer(-300, owner.position):
    owner.queue_free()
    
  owner.velocity.x = (speed - speed_modifier) * owner.dir
  if inv_counter < 7:
    inv_counter += 1 * Global.get_delta(delta)
  if !owner.alive:
    owner.gravity_scale = 0.8
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    if !temp:
      speed = owner.velocity.rotated(old_rotation).x * owner.dir
      #owner.animated_sprite.flip_v = false
      temp = true
    #owner.animated_sprite.flip_h = owner.velocity.rotated(old_rotation).x * -owner.dir < 0
    if speed_modifier < speed:
      speed_modifier += speed * 0.002
    return
  old_rotation = owner.rotation
  
  owner.animated_sprite.flip_h = owner.dir < 0
  
  var right_of_player: bool = owner.position.rotated(-owner.rotation).x > Global.Mario.position.rotated(-owner.rotation).x
  if owner.dir == (1 if right_of_player else -1):
    if speed_modifier < speed_cap:
      speed_modifier += 5 * Global.get_delta(delta)
    else:
      owner.dir = -1 if right_of_player else 1
  else:
    if abs(speed_modifier) > 0:
      speed_modifier -= 5 * Global.get_delta(delta)
  

func _on_hitbox_enter(a) -> void:
  if !owner.alive:
    return
  if a.name == 'BottomDetector' and !owner.invincible:
    inv_counter = 0
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars['bounce'] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars['bounce'] * 50
    owner.kill(AliveObject.DEATH_TYPE.FALL)
  elif a.name == 'InsideDetector' and inv_counter > 5:
    Global._ppd()
