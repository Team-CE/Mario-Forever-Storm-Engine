extends Node2D

export var x_speed: float = 0
export var y_speed: float = 0
export var jump_counter: int = 0
var can_jump: bool = false
var crouch: bool = false
var standing: bool = false

onready var dead: bool = false
onready var dead_counter: float = 0
onready var appear_counter: float = 0
onready var shield_counter: float = 0
onready var launch_counter: float = 0
onready var controls_enabled: bool = true
onready var animation_enabled: bool = true

signal top_detector_collide     #@reflexguru Implement these signals
signal bottom_detector_collide

signal left_detector_collide
signal right_detector_collide

func _ready() -> void:
  Global.Mario = self
  Global.connect("OnPlayerLoseLife", self, 'kill')
  $DebugText.visible = false

func is_over_backdrop(obj, ignore_hidden) -> bool:
  var overlaps = obj.get_overlapping_bodies()

  if overlaps.size() > 0 && (overlaps[0] is TileMap or overlaps[0].is_in_group('Solid')) and (overlaps[0].visible or ignore_hidden):
    return true

  return false

func is_over_platform(obj) -> bool:
  var overlaps = obj.get_overlapping_areas()

  if overlaps.size() > 0 && (overlaps[0].is_in_group('Platform')):
    return overlaps[0]
  
  return false

func _process(delta) -> void:
  _process_camera()

  if not dead:
    _process_alive(delta)
  else:
    _process_dead(delta)
  
  if y_speed > 10:
    y_speed = 10
  
  position.y += y_speed * Global.get_delta(delta)
  position.x += x_speed * Global.get_delta(delta)

func _process_alive(delta) -> void:
  if y_speed < 11:
    if Input.is_action_pressed('mario_jump') and not Input.is_action_pressed('mario_crouch') and y_speed < 0:
      if abs(x_speed) < 1:
        y_speed -= 0.4 * Global.get_delta(delta)
      else:
        y_speed -= 0.5 * Global.get_delta(delta)
    y_speed += 1 * Global.get_delta(delta)
    
  if controls_enabled:
    controls(delta)
  
  if x_speed > 0:
    x_speed -= 0.1 * Global.get_delta(delta)
  if x_speed < 0:
    x_speed += 0.1 * Global.get_delta(delta)
  
  if x_speed >= -0.1 and x_speed <= 0.1:
    x_speed = 0
  
  if y_speed > 0:
    jump_counter = 1
  
  if (is_over_backdrop($BottomDetector, false) or is_over_platform($BottomDetector)) and y_speed > 0:
    if is_over_backdrop($InsideDetector, false):
      position.y -= 16
    var platform = is_over_platform($BottomDetector)
    if platform:
      position.x += platform.horizontal_speed * Global.get_delta(delta)
    y_speed = 0
    standing = true
    jump_counter = 0
    position.y = round(position.y / 32) * 32
  
  if is_over_backdrop($TopDetector, true) and y_speed < 0 and y_speed > -13:
    y_speed = 0
  
  if not (is_over_backdrop($TopDetector, false) and not is_over_backdrop($PrimaryDetector, false)) and ((is_over_backdrop($RightDetector, false) and x_speed >= 0.08) or (is_over_backdrop($LeftDetector, false) and x_speed <= -0.08)):
    x_speed = 0
  
  if is_over_backdrop($SmallRightDetector, false) and not is_over_backdrop($SmallLeftDetector, false):
    position.x -= 1 * Global.get_delta(delta)
  
  if is_over_backdrop($SmallLeftDetector, false) and not is_over_backdrop($SmallRightDetector, false):
    position.x += 1 * Global.get_delta(delta)
  
  if is_over_backdrop($SmallRightDetector, false) and is_over_backdrop($SmallLeftDetector, false):
    position.x += (1 if $SmallMario.flip_h else -1) * Global.get_delta(delta)
  
  if position.y > $Camera.limit_bottom + 64 and controls_enabled:
    Global._pll()
  
  animate(delta)
  update_collisions()
  debug()

func _process_dead(delta) -> void:
  if dead_counter == 0:
    Global.state = 0
    animate(delta)
  
  $TopDetector/CollisionTop.disabled = true
  $BottomDetector/CollisionBottom.disabled = true
  $BottomDetector/CollisionBottomClose.disabled = true

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
  $TopDetector/CollisionTop.shape = null

  if dead_counter > 200:
    if Global.lives > 0:
      Global._reset()
    elif dead_counter < 201:
      MusicEngine.play_music('1-music-gameover.it')
      get_parent().get_node('HUD').get_node('GameoverSprite').visible = true
  pass

func controls(delta) -> void:
  if Input.is_action_just_pressed('mario_jump') and not Input.is_action_pressed('mario_crouch') and y_speed >= 0 and not crouch:
    can_jump = true
  if not Input.is_action_pressed('mario_jump'):
    can_jump = false

  if jump_counter == 0 and can_jump:
    standing = false
    y_speed = -14
    jump_counter = 1
    can_jump = false
    $BaseSounds/MAIN_Jump.play()
  
  if y_speed > 0.01 and not (is_over_backdrop($BottomDetector, false) or is_over_platform($BottomDetector)):
    standing = false
  
  if Input.is_action_pressed('mario_crouch') and (is_over_backdrop($BottomDetector, false) or is_over_platform($BottomDetector)) and Global.state > 0:
    crouch = true
    if x_speed > 0:
      x_speed -= 0.1 * Global.get_delta(delta)
    if x_speed < 0:
      x_speed += 0.1 * Global.get_delta(delta)
  else:
    crouch = false
  if not Input.is_action_pressed('mario_crouch'):
    crouch = false
  
  if Input.is_action_pressed('mario_right') and not crouch:
    if x_speed > -0.4 and x_speed < 0.4:
      x_speed = 0.8
    elif x_speed <= -0.4:
      x_speed += 0.4 * Global.get_delta(delta)
    elif x_speed < 3.5 and not Input.is_action_pressed('mario_fire'):
      x_speed += 0.25 * Global.get_delta(delta)
    elif x_speed < 7 and Input.is_action_pressed('mario_fire'):
      x_speed += 0.25 * Global.get_delta(delta)
    
  if Input.is_action_pressed('mario_left') and not crouch:
    if x_speed > -0.4 and x_speed < 0.4:
      x_speed = -0.8
    elif x_speed >= 0.4:
      x_speed -= 0.4 * Global.get_delta(delta)
    elif x_speed > -3.5 and not Input.is_action_pressed('mario_fire'):
      x_speed -= 0.25 * Global.get_delta(delta)
    elif x_speed > -7 and Input.is_action_pressed('mario_fire'):
      x_speed -= 0.25 * Global.get_delta(delta)
  
  if Input.is_action_just_pressed('mario_fire') and not crouch and Global.state > 1:
    if Global.state == 2 and Global.projectiles_count < 2:
      Global.play_base_sound('MAIN_Shoot')
      var fireball = load('res://Objects/Projectiles/Fireball.tscn').instance()
      fireball.dir = -1 if $SmallMario.flip_h else 1
      fireball.position = Vector2(position.x, position.y - 32)
      Global.projectiles_count += 1
      launch_counter = 2
      get_parent().add_child(fireball)

    if Global.state == 3 and Global.projectiles_count < 2:
      Global.play_base_sound('MAIN_Shoot')
      var beetroot = load('res://Objects/Projectiles/Beetroot.tscn').instance()
      beetroot.dir = -1 if $SmallMario.flip_h else 1
      beetroot.position = Vector2(position.x, position.y - 32)
      Global.projectiles_count += 1
      launch_counter = 2
      get_parent().add_child(beetroot)


func animate(delta) -> void:
  $SmallMario.visible = Global.state == 0
  $BigMario.visible = Global.state == 1
  $FlowerMario.visible = Global.state == 2
  $BeetrootMario.visible = Global.state == 3

  if not animation_enabled: return

  if x_speed <= -0.08:
    $SmallMario.flip_h = true
    $BigMario.flip_h = true
    $FlowerMario.flip_h = true
    $BeetrootMario.flip_h = true
  
  if x_speed >= 0.08:
    $SmallMario.flip_h = false
    $BigMario.flip_h = false
    $FlowerMario.flip_h = false
    $BeetrootMario.flip_h = false

  if appear_counter > 0:
    if not $SmallMario.animation == 'Appearing':
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
      $FlowerMario.visible = Global.state == 2 and calculated_invis
      $BeetrootMario.visible = Global.state == 3 and calculated_invis
  if shield_counter < 0:
    shield_counter = 0

  if launch_counter > 0:
    animate_sprite('Launching')
    launch_counter -= 1.01 * Global.get_delta(delta)
    return
  
  if crouch:
    animate_sprite('Crouching')
    return

  if not y_speed == 0 or not (is_over_backdrop($BottomDetector, false) or is_over_platform($BottomDetector)):
    animate_sprite('Jumping')
  elif abs(x_speed) < 0.08:
    animate_sprite('Stopped')
    
  if x_speed <= -0.08:
    if (y_speed == 0 and (is_over_backdrop($BottomDetector, false) or is_over_platform($BottomDetector))) or $SmallMario.animation == 'Launching':
      animate_sprite('Walking')
      
  if x_speed >= 0.08:
    if (y_speed == 0 and (is_over_backdrop($BottomDetector, false) or is_over_platform($BottomDetector))) or $SmallMario.animation == 'Launching':
      animate_sprite('Walking')
      
  if $SmallMario.animation == 'Walking':
    speed_scale_sprite(abs(x_speed) * 2.5 + 4)

func animate_sprite(anim_name) -> void:
  if anim_name != 'Crouching':
    $SmallMario.set_animation(anim_name);
  $BigMario.set_animation(anim_name)
  $FlowerMario.set_animation(anim_name)
  $BeetrootMario.set_animation(anim_name)

func speed_scale_sprite(scale_num) -> void:
  $SmallMario.speed_scale = scale_num
  $BigMario.speed_scale = scale_num
  $FlowerMario.speed_scale = scale_num
  $BeetrootMario.speed_scale = scale_num

func update_collisions() -> void:
  $PrimaryDetector/CollisionPrimary.disabled = not (Global.state == 0 or crouch)
  $TopDetector/CollisionTop.disabled = not (Global.state == 0 or crouch)
  $RightDetector/CollisionRight.disabled = not (Global.state == 0 or crouch)
  $LeftDetector/CollisionLeft.disabled = not (Global.state == 0 or crouch)
  $SmallRightDetector/CollisionSmallRight.disabled = not (Global.state == 0 or crouch)
  $SmallLeftDetector/CollisionSmallLeft.disabled = not (Global.state == 0 or crouch)

  $PrimaryDetector/CollisionPrimaryBig.disabled = not (Global.state > 0 and not crouch)
  $TopDetector/CollisionTopBig.disabled = not (Global.state > 0 and not crouch)
  $RightDetector/CollisionRightBig.disabled = not (Global.state > 0 and not crouch)
  $LeftDetector/CollisionLeftBig.disabled = not (Global.state > 0 and not crouch)
  $SmallRightDetector/CollisionSmallRightBig.disabled = not (Global.state > 0 and not crouch)
  $SmallLeftDetector/CollisionSmallLeftBig.disabled = not (Global.state > 0 and not crouch)

  $BottomDetector/CollisionBottom.disabled = not y_speed > 2 and not y_speed <= 0
  $BottomDetector/CollisionBottomClose.disabled = not y_speed <= 2

func kill() -> void:
  dead = true
  $PrimaryDetector/CollisionPrimary.shape = null
  $BottomDetector/CollisionBottom.shape = null

func debug() -> void:
  if Input.is_action_just_pressed('mouse_middle'):
    $DebugText.visible = !$DebugText.visible
  
  $DebugText.text = 'x speed = ' + str(x_speed) + '\ny speed = ' + str(y_speed) + '\nanimation: ' + str($BigMario.animation).to_lower() + '\nfps: ' + str(Engine.get_frames_per_second())

func _process_camera() -> void:
  if dead: return
  var base_y = floor((position.y + 240) / 960) * 960
  $Camera.limit_top = base_y
  $Camera.limit_bottom = base_y + 480
