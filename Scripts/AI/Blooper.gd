extends Brain

var approach_counter: float = 0
var timer: float = 0
var moving_up: bool = false
var move_to: Vector2
var rng = RandomNumberGenerator.new()

func _ready_mixin() -> void:
  owner.velocity_enabled = false
  owner.death_type = AliveObject.DEATH_TYPE.FALL
  rng.randomize()

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  var tween = owner.get_node('Tween')
  if owner.frozen or !owner.alive:
    tween.stop_all()
    owner.velocity_enabled = true
    owner.velocity.x = 0
    if !owner.is_on_floor():
      owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    return
  #if owner.is_on_wall():
  #  owner.turn()
  
  var calculated_dir = -1
  
  if approach_counter >= 0:
    owner.animated_sprite.frame = 0
  
  if (owner.position.y > Global.Mario.position.y - 48 and owner.position.y > Global.Mario.get_node('Camera').limit_top + 96) and approach_counter == 0:
    moving_up = true
    move_to = owner.position
    tween.interpolate_property(owner, 'position',
      owner.position, move_to + Vector2(72 * owner.dir, -96), 0.65,
      Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
    tween.start()
    tween.seek(0.1)
  if owner.position.y < Global.Mario.get_node('Camera').limit_top + 96 and moving_up:
    approach_counter = 25
    owner.position.y += 1
  
  if timer < 8:
    timer += 1 * Global.get_delta(delta)
  else:
    timer = 0
    calculated_dir = calculate_dir()
    if calculated_dir:
      owner.dir = calculated_dir
  
  if moving_up:
    approach_counter += 1 * Global.get_delta(delta)
    
    if approach_counter > 24:
      moving_up = false
      owner.animated_sprite.frame = 1
      approach_counter = -20
      tween.stop_all()
      
  else:
    owner.position.y += 2 * Global.get_delta(delta)
    if approach_counter < 0:
      approach_counter += 1 * Global.get_delta(delta)
    elif approach_counter > 0 and approach_counter < 0.99:
      approach_counter = 0
  
  if is_mario_collide('BottomDetector') and Global.Mario.velocity.y > 0 and owner.vars['can_stomp']:
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0, owner.sound)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50
  elif on_mario_collide('InsideDetector'):
    Global._ppd()

func calculate_dir() -> int:
  var mposx = Global.Mario.position.x
  if mposx - 256 > owner.position.x:
    return 1
  elif mposx + 256 < owner.position.x:
    return -1
  else:
    var mpos_math = int(abs((mposx - owner.position.x) / 8))
    var random = rng.randi_range(0, mpos_math)
    var result = mposx - owner.position.x if random < 1 else null
    if result and result > 0:
      result = 1
    elif result and result < 0:
      result = -1
    #print('Pos: ' + str(mpos_math) + ', rand: ' + str(random) + ', result: ' + str(result))
    return result

func getInfo() -> String:
  return str(moving_up) + '\nto: ' + str(move_to)
