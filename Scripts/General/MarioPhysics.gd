extends KinematicBody2D

var velocity: Vector2
export var jump_counter: int = 0
var jump_internal_counter: float = 100
var can_jump: bool = false
var crouch: bool = false
var standing: bool = false
var prelanding: bool = false

onready var dead: bool = false
onready var dead_counter: float = 0
onready var appear_counter: float = 0
onready var shield_counter: float = 0
onready var launch_counter: float = 0
onready var controls_enabled: bool = true
onready var animation_enabled: bool = true

func _ready() -> void:
  Global.Mario = self
# warning-ignore:return_value_discarded
  Global.connect("OnPlayerLoseLife", self, 'kill')
  $DebugText.visible = false

func is_over_backdrop(obj, ignore_hidden) -> bool:
  var overlaps = obj.get_overlapping_bodies()

  if overlaps.size() > 0 && (overlaps[0] is TileMap or overlaps[0].is_in_group('Solid')) and (overlaps[0].visible or ignore_hidden):
    return true

  return false

func is_over_platform() -> bool:
  if get_slide_count() > 0:
    var collider = get_slide_collision(0).collider
    return collider.is_in_group('Platform')
  else:
    return false

func _process(delta) -> void:
  _process_camera()

  if not dead:
    _process_alive(delta)
  else:
    _process_dead(delta)

  if velocity.y > 500:
    velocity.y = 500

  if jump_internal_counter < 100:
    jump_internal_counter += 1 * Global.get_delta(delta)

func _process_alive(delta) -> void:
  if velocity.y < 550 and not is_on_floor():
    if Input.is_action_pressed('mario_jump') and not Input.is_action_pressed('mario_crouch') and velocity.y < 0:
      if abs(velocity.x) < 1:
        velocity.y -= 20 * Global.get_delta(delta)
      else:
        velocity.y -= 25 * Global.get_delta(delta)
    velocity.y += 50 * Global.get_delta(delta)

  if controls_enabled:
    controls(delta)

  if velocity.x > 0:
    velocity.x -= 5 * Global.get_delta(delta)
  if velocity.x < 0:
    velocity.x += 5 * Global.get_delta(delta)

  if velocity.x > -5 and velocity.x < 5:
    velocity.x = 0

  if velocity.y > 0:
    jump_counter = 1

  if is_on_floor() and jump_internal_counter > 3:
    standing = true
    jump_counter = 0

  if position.y > $Camera.limit_bottom + 64 and controls_enabled:
    if get_parent().no_cliff:
      position.y -= 550
    else:
      if !get_parent().sgr_scroll:
        Global._pll()
      else:
        get_parent().get_node('StartWarp').active = true
        get_parent().get_node('StartWarp').counter = 61
      
  if position.y < $Camera.limit_top - 64 and controls_enabled and get_parent().no_cliff:
    position.y += 570

#  if is_on_floor() and velocity.y > -14 or is_on_ceiling():
#    velocity.y = 1
#    prelanding = true
#    if is_on_floor():
#      standing = true

  if is_on_ceiling():
    for i in range(get_slide_count()):
      var collider = get_slide_collision(i).collider
      if collider.has_method('hit'):
        collider.hit(delta)

  velocity = move_and_slide_with_snap(velocity.rotated(rotation), Vector2.ZERO, Vector2(0, -1), true, 4, 0.785398, false)

  animate(delta)
  update_collisions()
  debug()

func _process_dead(delta) -> void:
  if dead_counter == 0:
    Global.state = 0
    animate(delta)

  $TopDetector/CollisionTop.disabled = true
  $BottomDetector/CollisionBottom.disabled = true

  dead_counter += 1 * Global.get_delta(delta)
  $SmallMario.set_animation('Dead')
  velocity.x = 0

  velocity.y += 25 * Global.get_delta(delta)

  if dead_counter < 28:
    velocity.y = 0
  elif dead_counter >= 28 and dead_counter < 29:
    velocity.y = -550

  $BottomDetector/CollisionBottom.shape = null
  $TopDetector/CollisionTop.shape = null

  if dead_counter > 200:
    if Global.lives > 0:
      Global._reset()
    elif dead_counter < 201:
      MusicEngine.play_music('1-music-gameover.it')
      get_parent().get_node('HUD').get_node('GameoverSprite').visible = true

func controls(delta) -> void:
  if Input.is_action_just_pressed('mario_jump') and not Input.is_action_pressed('mario_crouch') and velocity.y >= 0 and not crouch:
    can_jump = true
  if not Input.is_action_pressed('mario_jump'):
    can_jump = false

  if jump_counter == 0 and can_jump:
    standing = false
    prelanding = false
    velocity.y = -700 # 650
    jump_counter = 1
    can_jump = false
    $BaseSounds/MAIN_Jump.play()
    jump_internal_counter = 0

  if velocity.y > 0.5 and not is_over_backdrop($BottomDetector, false):
    standing = false
    prelanding = false

  if Input.is_action_pressed('mario_crouch') and is_on_floor() and Global.state > 0:
    crouch = true
    if velocity.x > 0:
      velocity.x -= 5 * Global.get_delta(delta)
    if velocity.x < 0:
      velocity.x += 5 * Global.get_delta(delta)
  else:
    crouch = false
  if not Input.is_action_pressed('mario_crouch'):
    crouch = false

  if Input.is_action_pressed('mario_right') and not crouch:
    if velocity.x > -20 and velocity.x < 20:
      velocity.x = 40
    elif velocity.x <= -20:
      velocity.x += 20 * Global.get_delta(delta)
    elif velocity.x < 175 and not Input.is_action_pressed('mario_fire'):
      velocity.x += 12.5 * Global.get_delta(delta)
    elif velocity.x < 350 and Input.is_action_pressed('mario_fire'):
      velocity.x += 12.5 * Global.get_delta(delta)

  if Input.is_action_pressed('mario_left') and not crouch:
    if velocity.x > -20 and velocity.x < 20:
      velocity.x = -40
    elif velocity.x >= 20:
      velocity.x -= 20 * Global.get_delta(delta)
    elif velocity.x > -175 and not Input.is_action_pressed('mario_fire'):
      velocity.x -= 12.5 * Global.get_delta(delta)
    elif velocity.x > -350 and Input.is_action_pressed('mario_fire'):
      velocity.x -= 12.5 * Global.get_delta(delta)

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

  if velocity.x <= -4:
    $SmallMario.flip_h = true
    $BigMario.flip_h = true
    $FlowerMario.flip_h = true
    $BeetrootMario.flip_h = true

  if velocity.x >= 4:
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

  if not is_on_floor() and not (is_over_backdrop($BottomDetector, false) or is_over_platform()) and abs(velocity.y) > 2:
    animate_sprite('Jumping')
  elif abs(velocity.x) < 0.08:
    animate_sprite('Stopped')

  if velocity.x <= -0.08:
    if is_on_floor() or $SmallMario.animation == 'Launching':
      animate_sprite('Walking')

  if velocity.x >= 0.08:
    if is_on_floor() or $SmallMario.animation == 'Launching':
      animate_sprite('Walking')

  if $SmallMario.animation == 'Walking':
    speed_scale_sprite(abs(velocity.x / 50) * 2.5 + 4)

func animate_sprite(anim_name) -> void:
  if anim_name != 'Launching':
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
  $Collision.disabled = not (Global.state == 0 or crouch)
  $TopDetector/CollisionTop.disabled = not (Global.state == 0 or crouch)
  $InsideDetector/CollisionSmall.disabled = not (Global.state == 0 or crouch)
  $SmallRightDetector/CollisionSmallRight.disabled = not (Global.state == 0 or crouch)
  $SmallLeftDetector/CollisionSmallLeft.disabled = not (Global.state == 0 or crouch)
  
  $CollisionBig.disabled = not (Global.state > 0 and not crouch)
  $TopDetector/CollisionTopBig.disabled = not (Global.state > 0 and not crouch)
  $InsideDetector/CollisionBig.disabled = not (Global.state > 0 and not crouch)
  $SmallRightDetector/CollisionSmallRightBig.disabled = not (Global.state > 0 and not crouch)
  $SmallLeftDetector/CollisionSmallLeftBig.disabled = not (Global.state > 0 and not crouch)

func kill() -> void:
  dead = true
  $Collision.disabled = true
  $CollisionBig.disabled = true
  $BottomDetector/CollisionBottom.disabled = true

func debug() -> void:
  if Input.is_action_just_pressed('mouse_middle'):
    $DebugText.visible = !$DebugText.visible

  $DebugText.text = 'x speed = ' + str(velocity.x) + '\ny speed = ' + str(velocity.y) + '\nanimation: ' + str($BigMario.animation).to_lower() + '\nfps: ' + str(Engine.get_frames_per_second())

func _process_camera() -> void:
  if dead: return
  var base_y = floor((position.y + 240) / 960) * 960
  $Camera.limit_top = base_y
  $Camera.limit_bottom = base_y + 480
  
  if get_parent().sgr_scroll:
    var base_x = floor(position.x / 640) * 640
    $Camera.limit_left = base_x
    $Camera.limit_right = base_x + 640
