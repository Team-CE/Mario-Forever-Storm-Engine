extends KinematicBody2D

var gameover_music: Resource = preload('res://Music/1-music-gameover.ogg')

export var powerup_animations: Dictionary = {}
export var powerup_scripts: Dictionary = {}
export var target_gravity_angle: float = 0
export var sections_scroll: bool = true
export var camera_addon: Script

var inited_camera_addon

var ready_powerup_scripts: Dictionary = {}

var velocity: Vector2
var jump_counter: int = 0
var jump_internal_counter: float = 100
var can_jump: bool = false
var crouch: bool = false
var prelanding: bool = false

var top_collider_counter: float = 0

var position_altered: bool = false
var selected_state: int = -1

onready var dead: bool = false
onready var dead_hasJumped: bool = false
onready var dead_gameover: int = 0
onready var dead_counter: float = 0
onready var appear_counter: float = 0
onready var shield_counter: float = 0
onready var launch_counter: float = 0
onready var controls_enabled: bool = true
onready var animation_enabled: bool = true
onready var allow_custom_animation: bool = false

func _ready() -> void:
  gameover_music.loop = false
  Global.Mario = self
# warning-ignore:return_value_discarded
  Global.connect("OnPlayerLoseLife", self, 'kill')
  $DebugText.visible = false
  
  if camera_addon:
    inited_camera_addon = camera_addon.new()
    if inited_camera_addon.has_method('_ready_camera'):
      inited_camera_addon._ready_camera(self)
  
  # Creating working instances of provided scripts
  var p_keys = powerup_scripts.keys()
  for i in range(len(p_keys)):
    ready_powerup_scripts[p_keys[i]] = powerup_scripts[p_keys[i]].new()

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
  _process_camera(delta)
  
  var target_gravity_enabled: bool = true
  var overlaps = $InsideDetector.get_overlapping_areas()
  for i in overlaps:
    if 'gravity_point' in i and i.gravity_point:
      target_gravity_enabled = false
      
  if target_gravity_enabled:
    rotation = lerp_angle(rotation, deg2rad(target_gravity_angle), 0.15)
  else:
    target_gravity_angle = rotation_degrees
    
  $Sprite.modulate.a = 0.5 if Global.debug_fly else 1
  
  $BottomDetector/CollisionBottom.position.y = 5 + velocity.y / 50 * Global.get_delta(delta)

  if not dead:
    if not Global.debug_fly:
      _process_alive(delta)
    else:
      _process_debug_fly(delta)
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
    
  if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_process_mixin'):
    ready_powerup_scripts[Global.state]._process_mixin(self, delta)
    
  if not Global.state == 6:
    allow_custom_animation = false
    $BottomDetector/CollisionBottom.scale.y = 0.5

  if controls_enabled:
    controls(delta)

  if velocity.x > 0:
    velocity.x -= 5 * Global.get_delta(delta)
  if velocity.x < 0:
    velocity.x += 5 * Global.get_delta(delta)

  if velocity.x > -10 * Global.get_delta(delta) and velocity.x < 10 * Global.get_delta(delta):
    velocity.x = 0

  if velocity.y > 0:
    jump_counter = 1

  if is_on_floor() and jump_internal_counter > 3:
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
  if top_collider_counter > 0:
    top_collider_counter -= 1 * Global.get_delta(delta)

  if is_on_ceiling():
    top_collider_counter = 3

  if top_collider_counter > 0:
    var collisions = $TopDetector.get_overlapping_bodies()
    for i in range(len(collisions)):
      var collider = collisions[i]
      if collider.has_method('hit'):
        collider.hit(delta)
        
  var bottom_collisions = $BottomDetector.get_overlapping_bodies()
  if is_on_floor():
    for i in range(len(bottom_collisions)):
      var collider = bottom_collisions[i]
      if collider.has_method('_standing_on'):
        collider._standing_on()

  velocity = move_and_slide_with_snap(velocity.rotated(rotation), Vector2(0, 1).rotated(rotation), Vector2(0, -1).rotated(rotation), true, 4, 0.785398, false).rotated(-rotation)

  animate(delta)
  update_collisions()
  debug()
  
  $Sprite.offset.y = 0 - $Sprite.frames.get_frame($Sprite.animation, $Sprite.frame).get_size().y
  $Sprite.offset.x = 0 - $Sprite.frames.get_frame($Sprite.animation, $Sprite.frame).get_size().x / 2

func _process_dead(delta) -> void:
  if dead_counter == 0:
    Global.state = 0
    animate(delta)

  $TopDetector/CollisionTop.disabled = true
  $BottomDetector/CollisionBottom.disabled = true

  dead_counter += 1 * Global.get_delta(delta)
  $Sprite.set_animation('Dead')
  velocity.x = 0
  
  velocity.y += 25 * Global.get_delta(delta)

  if dead_counter < 24:
    velocity.y = 0
  elif not dead_hasJumped:
    dead_hasJumped = true
    velocity.y = -550
    
  $Sprite.position += Vector2(0, velocity.y * delta)

  $BottomDetector/CollisionBottom.shape = null
  $TopDetector/CollisionTop.shape = null

  if dead_counter > 180:
    if Global.lives > 0:
      Global._reset()
    elif not dead_gameover:
      MusicPlayer.stream = gameover_music
      MusicPlayer.play()
      get_parent().get_node('HUD').get_node('GameoverSprite').visible = true
      dead_gameover = 1
      yield(get_tree().create_timer( 4.0 ), 'timeout')
      dead_gameover = 2

func _input(event) -> void:
  if dead_gameover == 2:
    if event.is_pressed():
      dead_gameover = false
      Global.lives = 4
      Global.score = 0
      Global.coins = 0
      Global.state = 0
      Global.projectiles_count = 0
      Global.checkpoint_active = 0
      Global.gameoverLevel = get_tree().current_scene.filename
      get_tree().change_scene('res://Stages/GameOverContinue.tscn')
  else:
    return
      
func _process_debug_fly(delta: float) -> void:
  var debugspeed: int = 10 + (int(Input.is_action_pressed('mario_fire')) * 10) * Global.get_delta(delta)
  if Input.is_action_pressed('mario_right'):
    position.x += debugspeed
  if Input.is_action_pressed('mario_left'):
    position.x -= debugspeed
  
  if Input.is_action_pressed('mario_up'):
    position.y -= debugspeed
  if Input.is_action_pressed('mario_crouch'):
    position.y += debugspeed
    
  if Input.is_action_just_pressed('debug_rotate_right'):
    target_gravity_angle += 45
    
  if Input.is_action_just_pressed('debug_rotate_left'):
    target_gravity_angle -= 45

func controls(delta) -> void:
  if Input.is_action_just_pressed('mario_jump') and not Input.is_action_pressed('mario_crouch') and not crouch:
    can_jump = true
  if not Input.is_action_pressed('mario_jump'):
    can_jump = false

  if jump_counter == 0 and can_jump:
    prelanding = false
    velocity.y = -700 # 650
    jump_counter = 1
    can_jump = false
    $BaseSounds/MAIN_Jump.play()
    jump_internal_counter = 0

  if velocity.y > 0.5 and not is_over_backdrop($BottomDetector, false):
    prelanding = false

  if Input.is_action_pressed('mario_crouch') and is_on_floor() and Global.state > 0:
    crouch = true
    velocity.y = 1
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
    if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('do_action'):
      ready_powerup_scripts[Global.state].do_action(self)

func animate(delta) -> void:
  if not animation_enabled: return
  
  if selected_state != Global.state:
    selected_state = Global.state
    if not Global.state in powerup_animations:
      printerr('[CE ERROR] Mario: Animations for state ' + str(Global.state) + ' don\'t exist!')
      return
    $Sprite.frames = powerup_animations[Global.state]

  if velocity.x <= -8 * Global.get_delta(delta):
    $Sprite.flip_h = true
  if velocity.x >= 8 * Global.get_delta(delta):
    $Sprite.flip_h = false
    
#  if Global.state > 0 and not position_altered:
#    $Sprite.position.y -= 14
#    position_altered = true

  if appear_counter > 0:
    if not allow_custom_animation:
      if not $Sprite.animation == 'Appearing':
        animate_sprite('Appearing')
      $Sprite.speed_scale = 1
      
    appear_counter -= 1.5 * Global.get_delta(delta)
    return
  if appear_counter < 0:
#    if position_altered:
#      $Sprite.position.y += 14
#      position_altered = false
    appear_counter = 0

  if shield_counter > 0:
    shield_counter -= 1.5 * Global.get_delta(delta)
    if appear_counter == 0:
      $Sprite.visible = int(shield_counter / 2) % 2 == 0
  if shield_counter < 0:
    shield_counter = 0
    $Sprite.visible = true
#  $Sprite.offset.y = $Sprite.texture.get_size()

  if allow_custom_animation: return

  if launch_counter > 0:
    animate_sprite('Launching')
    launch_counter -= 1.01 * Global.get_delta(delta)
    return

  if crouch:
    if Global.state > 0:
      animate_sprite('Crouching')
    else:
      animate_sprite('Stopped')
    return

  if not is_on_floor() and not is_over_platform() and abs(velocity.y) > 2:
    animate_sprite('Jumping')
  elif abs(velocity.x) < 0.08 and is_on_floor():
    animate_sprite('Stopped')

  if velocity.x <= -0.16 * Global.get_delta(delta):
    if is_on_floor() or $Sprite.animation == 'Launching':
      animate_sprite('Walking')

  if velocity.x >= 0.16 * Global.get_delta(delta):
    if is_on_floor() or $Sprite.animation == 'Launching':
      animate_sprite('Walking')

  if $Sprite.animation == 'Walking':
    $Sprite.speed_scale = abs(velocity.x / 50) * 2.5 + 4

func animate_sprite(anim_name) -> void:
  $Sprite.set_animation(anim_name)

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

  $DebugText.text = 'x speed = ' + str(velocity.x) + '\ny speed = ' + str(velocity.y) + '\nanimation: ' + str($Sprite.animation).to_lower() + '\nfps: ' + str(Engine.get_frames_per_second())

func _process_camera(delta: float) -> void:
  if dead: return
  
  if sections_scroll:
    var base_y = floor((position.y + 240) / 960) * 960
    $Camera.limit_top = base_y
    $Camera.limit_bottom = base_y + 480
  
  if inited_camera_addon and inited_camera_addon.has_method('_process_camera'):
    inited_camera_addon._process_camera(self, delta)
  
  if get_parent().sgr_scroll:
    var base_x = floor(position.x / 640) * 640
    $Camera.limit_left = base_x
    $Camera.limit_right = base_x + 640
    
func _physics_process(_delta: float) -> void:
  if inited_camera_addon and inited_camera_addon.has_method('_process_physics_camera'):
    inited_camera_addon._process_physics_camera(self, _delta)
  if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_process_mixin_physics') and not dead:
    ready_powerup_scripts[Global.state]._process_mixin_physics(self, _delta)
