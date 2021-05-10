extends Node2D

export var x_speed: float = 0
export var y_speed: float = 0
export var jump_counter: int = 0
var can_jump: bool = false

onready var dead = false
onready var dead_counter = 0
onready var appear_counter = 0
onready var shield_counter = 0

func _ready() -> void:
  Global.Mario = self
  Global.connect("OnPlayerLoseLife",self,'kill')
  $DebugText.visible = false

func is_over_backdrop(obj, ignore_hidden) -> bool:
  var overlaps = obj.get_overlapping_bodies()

  if overlaps.size() > 0:
    for i in range(overlaps.size()):
      if (overlaps[0] is TileMap or overlaps[0].is_in_group('Solid')) and (overlaps[0].visible or ignore_hidden):
        return true

  return false

func _process(delta) -> void:
  if not dead:
    _process_alive(delta)
  else:
    _process_dead(delta)
  
  position.y += y_speed * Global.get_delta(delta)
  position.x += x_speed * Global.get_delta(delta)

func _process_alive(delta) -> void:
  if y_speed < 11:
    if Input.is_action_pressed('mario_jump') and y_speed < 0:
      if abs(x_speed) < 1:
        y_speed -= 0.4 * Global.get_delta(delta)
      else:
        y_speed -= 0.5 * Global.get_delta(delta)
    y_speed += 1 * Global.get_delta(delta)
  if y_speed > 10:
    y_speed = 10
    
  controls(delta)
  
  if x_speed > 0:
    x_speed -= 0.1 * Global.get_delta(delta)
  if x_speed < 0:
    x_speed += 0.1 * Global.get_delta(delta)
  
  if x_speed >= -0.08 and x_speed <= 0.08:
    x_speed = 0
  
  if y_speed > 0:
    jump_counter = 1
  
  if is_over_backdrop($BottomDetector, false) and y_speed > 0:
    if is_over_backdrop($InsideDetector, false):
      position.y -= 16
    y_speed = 0
    jump_counter = 0
    position.y = round(position.y / 32) * 32
  
  if is_over_backdrop($TopDetector, true) and y_speed < 0 and y_speed > -13:
    y_speed = 0
    position.y = round(position.y / 8) * 8
  
  if not (is_over_backdrop($TopDetector, false) and not is_over_backdrop($PrimaryDetector, false)) and ((is_over_backdrop($RightDetector, false) and x_speed >= 0.08) or (is_over_backdrop($LeftDetector, false) and x_speed <= -0.08)):
    x_speed = 0
  
  if is_over_backdrop($SmallRightDetector, false):
    position.x -= 1 * Global.get_delta(delta)
  
  if is_over_backdrop($SmallLeftDetector, false):
    position.x += 1 * Global.get_delta(delta)
  
  if is_over_backdrop($SmallRightDetector, false) and is_over_backdrop($SmallLeftDetector, false):
    position.x += (1 if $SmallMario.flip_h else -1) * Global.get_delta(delta)
  
  if position.y > $Camera.limit_bottom + 64:
    Global._pll()
  
  animate(delta)
  debug()

func _process_dead(delta) -> void:
  if dead_counter == 0:
    Global.state = 0
    animate(delta)

  dead_counter += 1 * Global.get_delta(delta)
  $SmallMario.set_animation('Dead')
  x_speed = 0

  y_speed += 0.5 * Global.get_delta(delta)

  if dead_counter < 28:
    y_speed = 0
  elif dead_counter >= 28 and dead_counter < 29:
    y_speed = -11

  $PrimaryDetector/CollisionPrimary.shape = null
  $BottomDetector/CollisionBottom.shape = null

  if dead_counter > 200:
    if Global.lives > 0:
      Global._reset()
    elif dead_counter < 201:
      MusicEngine.play_music('1-music-gameover.it')
      get_parent().get_node('HUD').get_node('GameoverSprite').visible = true
  pass

func controls(delta) -> void:
  if Input.is_action_just_pressed('mario_jump') and y_speed >= 0:
    can_jump = true
  if not Input.is_action_pressed('mario_jump'):
    can_jump = false

  if jump_counter == 0 and can_jump:
    y_speed = -13
    jump_counter = 1
    can_jump = false
    $BaseSounds/MAIN_Jump.play()
  
  if Input.is_action_pressed('mario_right'):
    if x_speed > -0.4 and x_speed < 0.4:
      x_speed = 0.8
    elif x_speed <= -0.4:
      x_speed += 0.4 * Global.get_delta(delta)
    elif x_speed < 3.5 and not Input.is_action_pressed('mario_fire'):
      x_speed += 0.25 * Global.get_delta(delta)
    elif x_speed < 7 and Input.is_action_pressed('mario_fire'):
      x_speed += 0.25 * Global.get_delta(delta)
    
  if Input.is_action_pressed('mario_left'):
    if x_speed > -0.4 and x_speed < 0.4:
      x_speed = -0.8
    elif x_speed >= 0.4:
      x_speed -= 0.4 * Global.get_delta(delta)
    elif x_speed > -3.5 and not Input.is_action_pressed('mario_fire'):
      x_speed -= 0.25 * Global.get_delta(delta)
    elif x_speed > -7 and Input.is_action_pressed('mario_fire'):
      x_speed -= 0.25 * Global.get_delta(delta)

func animate(delta) -> void:
  $SmallMario.visible = Global.state == 0
  $BigMario.visible = Global.state == 1

  if x_speed <= -0.8:
    $SmallMario.flip_h = true
    $BigMario.flip_h = true
  
  if x_speed >= 0.8:
    $SmallMario.flip_h = false
    $BigMario.flip_h = false

  if appear_counter > 0:
    if not $SmallMario.animation == 'Appearing':
      print('anim set')
      animate_sprite('Appearing')
      $SmallMario.position.y -= 13
    
    speed_scale_sprite(1)
    appear_counter -= 1.5 * Global.get_delta(delta)
    return
  if appear_counter < 0:
    $SmallMario.position.y += 13
    appear_counter = 0
  
  if shield_counter > 0:
    shield_counter -= 1.5 * Global.get_delta(delta)
    if appear_counter == 0:
      var calculated_invis = int(shield_counter / 2) % 2 == 0
      $SmallMario.visible = Global.state == 0 and calculated_invis
      $BigMario.visible = Global.state == 1 and calculated_invis
  if shield_counter < 0:
    shield_counter = 0

  if not y_speed == 0:
    animate_sprite('Jumping')
  elif abs(x_speed) < 0.8:
    animate_sprite('Stopped')
    
  if x_speed <= -0.8:
    if not $SmallMario.animation == 'Walking' and y_speed == 0:
      animate_sprite('Walking')
      
  if x_speed >= 0.8:
    if not $SmallMario.animation == 'Walking' and y_speed == 0:
      animate_sprite('Walking')
      
  if $SmallMario.animation == 'Walking':
    speed_scale_sprite(abs(x_speed) * 2.5 + 4)

func animate_sprite(anim_name) -> void:
  $SmallMario.set_animation(anim_name)
  $BigMario.set_animation(anim_name)

func speed_scale_sprite(scale_num) -> void:
  $SmallMario.speed_scale = scale_num
  $BigMario.speed_scale = scale_num

func kill() -> void:
  dead = true
  $PrimaryDetector/CollisionPrimary.shape = null
  $BottomDetector/CollisionBottom.shape = null

func debug() -> void:
  if Input.is_action_just_pressed('mouse_middle'):
    $DebugText.visible = !$DebugText.visible
  
  $DebugText.text = 'x speed = ' + str(x_speed) + '\ny speed = ' + str(y_speed) + '\nanimation: ' + str($SmallMario.animation).to_lower() + '\nfps: ' + str(Engine.get_frames_per_second())

