extends KinematicBody2D

var gameover_music: Resource = preload('res://Music/1-music-gameover.ogg')

export var powerup_animations: Dictionary = {}
export var powerup_scripts: Dictionary = {}
export var target_gravity_angle: float = 0
export var sections_scroll: bool = true
export var camera_addon: Script
export var die_music: Resource = preload('res://Music/1-music-die.ogg')
export var custom_die_stream: Resource

var inited_camera_addon

var ready_powerup_scripts: Dictionary = {}

var velocity: Vector2
var old_velocity: Vector2
var reset_velocity: int = 0
var jump_counter: int = 0
var jump_internal_counter: float = 100
var can_jump: bool = false
var crouch: bool = false
var is_stuck: bool = false
var prelanding: bool = false

enum Movement {
  DEFAULT,
  SWIMMING,
  CLIMBING
 }

var top_collider_counter: float = 0

var position_altered: bool = false
var selected_state: int = -1

onready var movement_type: int = Movement.DEFAULT
onready var dead: bool = false
onready var dead_hasJumped: bool = false
onready var dead_gameover: bool = false
onready var dead_counter: float = 0
onready var appear_counter: float = 0
onready var shield_star: bool = false
onready var shield_counter: float = 0
onready var star_kill_count: int = 0
onready var launch_counter: float = 0
onready var controls_enabled: bool = true
onready var animation_enabled: bool = true
onready var allow_custom_animation: bool = false
onready var invulnerable: bool = false               # True while warping or finishing the level

onready var ray_R: RayCast2D = $RayCastRight
onready var ray_L: RayCast2D = $RayCastLeft
onready var ray_R_2: RayCast2D = $RayCastRight2
onready var ray_L_2: RayCast2D = $RayCastLeft2

var faded: bool = false

const pause_menu = preload('res://Objects/Tools/PopupMenu.tscn')
var popup: CanvasLayer = null

onready var cam: Camera2D
func get_camera() -> Camera2D:
  return cam

func change_camera_parent() -> void:
  if cam.get_parent() != self:
    get_tree().current_scene.remove_child(cam)
    cam.set_owner(self)
    add_child(cam)
  else:
    remove_child(cam)
    cam.set_owner(get_tree().current_scene)
    get_tree().current_scene.add_child(cam)

func _ready() -> void:
  gameover_music.loop = false
  die_music.loop = false
  Global.Mario = self
# warning-ignore:return_value_discarded
  Global.connect('OnPlayerLoseLife', self, 'kill')
  $DebugText.visible = false
  $Sprite.material.set_shader_param('mixing', false)
  
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
  if get_node_or_null('Camera'):
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
    
  #$Sprite.modulate.a = 0.5 if Global.debug_fly else 1
  
  $BottomDetector/CollisionBottom.position.y = 5 + velocity.y / 100 * Global.get_delta(delta)

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
  if selected_state != Global.state:
    selected_state = Global.state
    if selected_state > 0 and test_move(Transform2D(rotation, position), Vector2(0, -6).rotated(rotation)):
      velocity.y = 0
      crouch = true
      is_stuck = true
    if not Global.state in powerup_animations:
      printerr('[CE ERROR] Mario: Animations for state ' + str(Global.state) + ' don\'t exist!')
      return
    if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_ready_mixin'):
      ready_powerup_scripts[Global.state]._ready_mixin(self)
    $Sprite.frames = powerup_animations[Global.state]

  if velocity.x > 1 or velocity.x < -1 or velocity.y < -1:
    old_velocity = velocity
    reset_velocity = 0
  
  var danimate: bool = false
  if movement_type == Movement.SWIMMING:  # Faster than match
    movement_swimming(delta)
  elif movement_type == Movement.CLIMBING:
    movement_climbing(delta)
  else:
    danimate = true
    movement_default(delta)
  
  if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_process_mixin'):
    ready_powerup_scripts[Global.state]._process_mixin(self, delta)
    
  if not Global.state == 6: # Fix for propeller powerup animation
    allow_custom_animation = false
    $BottomDetector/CollisionBottom.scale.y = 0.5
  
  
  if shield_star:
    star_logic()
    $BottomDetector/CollisionBottom.disabled = true
    $BottomDetector/CollisionBottom2.disabled = true
    $Sprite.material.set_shader_param('mixing', true)
    # Starman music Fade out
    
    if shield_counter <= 125 and Global.musicBar > -100 and !faded:
      MusicPlayer.fade_out(MusicPlayer.get_node('Star'), 3.0)
      faded = true
    if shield_counter <= 0:
      MusicPlayer.get_node('Star').stop()
      MusicPlayer.get_node('Main').play()
      $BottomDetector/CollisionBottom.disabled = false
      $BottomDetector/CollisionBottom2.disabled = false
      $Sprite.material.set_shader_param('mixing', false)
      if Global.musicBar > -100:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
      if Global.musicBar == -100:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
      shield_star = false
      star_kill_count = 0
  
  if controls_enabled:
    controls(delta)
  
  if position.y > $Camera.limit_bottom + 64 and controls_enabled:
    if 'no_cliff' in get_parent() and get_parent().no_cliff:
      position.y -= 550
    else:
      if 'sgr_scroll' in get_parent() and !get_parent().sgr_scroll:
        Global._pll()
      elif get_node_or_null('../StartWarp'):
        get_node('../StartWarp').active = true
        get_node('../StartWarp').counter = 61
      
  if position.y < $Camera.limit_top - 64 and controls_enabled and 'no_cliff' in get_parent() and get_parent().no_cliff:
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
    for collider in collisions:
      if collider.has_method('hit'):
        collider.hit(delta)
        
  var bottom_collisions = $BottomDetector.get_overlapping_bodies()
  if is_on_floor():
    for collider in bottom_collisions:
      if collider.has_method('_standing_on'):
        collider._standing_on()

  if old_velocity:
    if reset_velocity > 2:
      old_velocity = Vector2.ZERO
    reset_velocity += 1
  
  if old_velocity != Vector2.ZERO and velocity.y > 1:
    one_tile_gap(old_velocity.x)
    
  velocity = move_and_slide_with_snap(velocity.rotated(rotation), Vector2(0, 1).rotated(rotation), Vector2(0, -1).rotated(rotation), true, 4, 0.785398, false).rotated(-rotation)
  update_collisions()
    
  if animation_enabled and danimate: animate_default(delta)
  debug()
  
  $Sprite.offset.y = 0 - $Sprite.frames.get_frame($Sprite.animation, $Sprite.frame).get_size().y
  $Sprite.offset.x = 0 - $Sprite.frames.get_frame($Sprite.animation, $Sprite.frame).get_size().x / 2

func _process_dead(delta) -> void:
  if dead_counter == 0:
    Global.state = 0
    $Sprite.frames = powerup_animations[0]
    animate_default(delta)
  
  var colDisabled
  if not colDisabled:
    $TopDetector/CollisionTop.disabled = true
    $BottomDetector/CollisionBottom.disabled = true
    $Collision.disabled = true
    $CollisionBig.disabled = true
    $BottomDetector/CollisionBottom.disabled = true
    $BottomDetector/CollisionBottom2.disabled = true
    $InsideDetector.collision_layer = 0
    $InsideDetector.collision_mask = 0
    $Sprite.material.set_shader_param('mixing', false)
    colDisabled = true

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

  #$BottomDetector/CollisionBottom.shape = null
  #$TopDetector/CollisionTop.shape = null

  if dead_counter > 180:
    if Global.lives > 0:
      Global._reset()
    elif not dead_gameover:
      MusicPlayer.get_node('Main').stream = gameover_music
      MusicPlayer.get_node('Main').play()
      get_parent().get_node('HUD').get_node('GameoverSprite').visible = true
      dead_gameover = true
      yield(get_tree().create_timer( 5.0, false ), 'timeout')
      if popup == null:
        popup = pause_menu.instance()
        for node in popup.get_children():
          if node.get_class() == 'Node' and not node.get_name() == 'GameOver':
            node.queue_free()
        get_parent().add_child(popup)

        get_parent().get_tree().paused = true
      
func movement_default(delta) -> void:
  if Global.is_mario_collide_area_group('InsideDetector', 'Water'):
    movement_type = Movement.SWIMMING
  
  if velocity.y < 550 and !is_on_floor():
    if Input.is_action_pressed('mario_jump') and !Input.is_action_pressed('mario_crouch') and velocity.y < 0:
      if abs(velocity.x) < 1:
        velocity.y -= 20 * Global.get_delta(delta)
      else:
        velocity.y -= 25 * Global.get_delta(delta)
    velocity.y += 50 * Global.get_delta(delta)
  
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
  
  # Start climbing
  if Input.is_action_pressed('mario_up') || (Input.is_action_pressed('mario_crouch') && !is_on_floor()):
    if crouch || !is_over_vine(): return
    if movement_type == Movement.DEFAULT:
      controls_enabled = false
      movement_type = Movement.CLIMBING

func movement_swimming(delta) -> void:
  if animation_enabled:
    animate_swimming(delta, Input.is_action_just_pressed('mario_jump') and !crouch and !Input.is_action_pressed('mario_crouch'))
  
  if velocity.x > 0:
    velocity.x -= 5 * Global.get_delta(delta)
  if velocity.x < 0:
    velocity.x += 5 * Global.get_delta(delta)
  
  #Water restrictions
  if velocity.x > 175:
    velocity.x -= 15 * Global.get_delta(delta)
  if velocity.x < -175:
    velocity.x += 15 * Global.get_delta(delta)

  if velocity.x > -10 * Global.get_delta(delta) and velocity.x < 10 * Global.get_delta(delta):
    velocity.x = 0
  
  if velocity.y < 165:
    velocity.y += 5 * Global.get_delta(delta)
  
  if velocity.y > 165 + (50 * Global.get_delta(delta)):
    velocity.y -= 50 * Global.get_delta(delta)
  elif velocity.y > 165:
    velocity.y = 165
  
  if Input.is_action_just_pressed('mario_jump') and !crouch and !Input.is_action_pressed('mario_crouch'):
    Global.play_base_sound('MAIN_Swim')
    if Global.is_mario_collide_area_group('TopDetector', 'Water'):
      velocity.y = -161.5
    else:
      velocity.y = -484.5
    
  if !Global.is_mario_collide_area_group('InsideDetector', 'Water'):
    movement_type = Movement.DEFAULT

  if can_jump: can_jump = false

func movement_climbing(delta) -> void:
  if animation_enabled: animate_climbing(delta)
  
  if !is_over_vine():
    movement_type = Movement.DEFAULT
    controls_enabled = true
  
  if Input.is_action_pressed('mario_crouch'):
    if is_on_floor():
      movement_type = Movement.DEFAULT
      controls_enabled = true
    else:
      velocity.y = 180
  if Input.is_action_pressed('mario_up'):
    velocity.y = -180
  if Input.is_action_pressed('mario_left'):
    velocity.x = -150
  if Input.is_action_pressed('mario_right'):
    velocity.x = 150
  
  if !Input.is_action_pressed('mario_crouch') and !Input.is_action_pressed('mario_up'):
    velocity.y = 0
  if !Input.is_action_pressed('mario_left') and !Input.is_action_pressed('mario_right'):
    velocity.x = 0
    
func is_over_vine() -> bool:
  var overlaps = get_node('InsideDetector').get_overlapping_areas()
  for c in overlaps:
    if c.is_in_group('Climbable'):
      return true
  return false

func jump() -> void:
  prelanding = false
  velocity.y = -700 # 650
  jump_counter = 1
  can_jump = false
  $BaseSounds/MAIN_Jump.play()
  jump_internal_counter = 0

func controls(delta) -> void:
  if (
      Input.is_action_just_pressed('mario_jump') and
      not Input.is_action_pressed('mario_crouch') and
      not crouch and
      movement_type != Movement.SWIMMING
    ):
    can_jump = true
  if not Input.is_action_pressed('mario_jump'):
    can_jump = false

  if jump_counter == 0 and can_jump and movement_type != Movement.SWIMMING:
    jump()

  if velocity.y > 0.5 and not is_over_backdrop($BottomDetector, false):
    prelanding = false

  if is_on_floor() and Global.state > 0:
    if Input.is_action_pressed('mario_crouch'):
      crouch = true
      is_stuck = false
      velocity.y = 1
      if velocity.x > 0:
        velocity.x -= 6.25 * Global.get_delta(delta) if !Input.is_action_pressed('mario_right') else 2.5 * Global.get_delta(delta)
      if velocity.x < 0:
        velocity.x += 6.25 * Global.get_delta(delta) if !Input.is_action_pressed('mario_left') else 2.5 * Global.get_delta(delta)
    else:
      if !test_move(Transform2D(rotation, position), Vector2(0, -6).rotated(rotation)):
        crouch = false
        is_stuck = false
      else:
        is_stuck = true
        velocity = Vector2.DOWN
  else:
    if !test_move(Transform2D(rotation, position), Vector2(0, -6).rotated(rotation)):
      crouch = false
      is_stuck = false
    #else:
    #  crouch = true
    #  is_stuck = true
  #if not Input.is_action_pressed('mario_crouch'):
  #  crouch = false
  if Global.state == 0:
    crouch = false
    is_stuck = false
  
  if is_stuck:
    var collisions = $TopDetector.get_overlapping_bodies()
    for collider in collisions:
      if collider.has_method('hit'):
        collider.hit(delta)
    
    var left_collide: bool = test_move(Transform2D(rotation, position + Vector2(-16, 0).rotated(rotation)), Vector2(0, -6).rotated(rotation))
    var right_collide: bool = test_move(Transform2D(rotation, position + Vector2(16, 0).rotated(rotation)), Vector2(0, -6).rotated(rotation))
    if left_collide and right_collide:
      position += Vector2(1, 0).rotated(rotation) * Global.get_vector_delta(delta) if $Sprite.flip_h else Vector2(-1, 0).rotated(rotation) * Global.get_vector_delta(delta)
    if left_collide and !right_collide:
      position += Vector2(1, 0).rotated(rotation) * Global.get_vector_delta(delta)
    if right_collide and !left_collide:
      position += Vector2(-1, 0).rotated(rotation) * Global.get_vector_delta(delta)

  if Input.is_action_pressed('mario_right') and not crouch:
    if velocity.x > -20 and velocity.x < 20:
      velocity.x = 40
    elif velocity.x <= -20:
      velocity.x += 20 * Global.get_delta(delta)
    elif velocity.x < 175 and (not Input.is_action_pressed('mario_fire') or movement_type == Movement.SWIMMING):
      velocity.x += 12.5 * Global.get_delta(delta)
    elif velocity.x < 350 and Input.is_action_pressed('mario_fire') and movement_type != Movement.SWIMMING:
      velocity.x += 12.5 * Global.get_delta(delta)

  if Input.is_action_pressed('mario_left') and not crouch:
    if velocity.x > -20 and velocity.x < 20:
      velocity.x = -40
    elif velocity.x >= 20:
      velocity.x -= 20 * Global.get_delta(delta)
    elif velocity.x > -175 and (not Input.is_action_pressed('mario_fire') or movement_type == Movement.SWIMMING):
      velocity.x -= 12.5 * Global.get_delta(delta)
    elif velocity.x > -350 and Input.is_action_pressed('mario_fire') and movement_type != Movement.SWIMMING:
      velocity.x -= 12.5 * Global.get_delta(delta)

  if Input.is_action_just_pressed('mario_fire') and not crouch and Global.state > 1:
    if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('do_action'):
      ready_powerup_scripts[Global.state].do_action(self)

func animate_default(delta) -> void:
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
    if not shield_star: return
  if appear_counter < 0:
#    if position_altered:
#      $Sprite.position.y += 14
#      position_altered = false
    appear_counter = 0

  if shield_counter > 0:
    shield_counter -= 1.5 * Global.get_delta(delta)
    if appear_counter == 0 and not shield_star:
      $Sprite.visible = int(shield_counter / 2) % 2 == 0
    if appear_counter > 0: return
  if shield_counter < 0:
    shield_counter = 0
    $Sprite.visible = true
#  $Sprite.offset.y = $Sprite.texture.get_size()

  if allow_custom_animation: return

  if launch_counter > 0:
    animate_sprite('Launching')
    launch_counter -= 1.01 * Global.get_delta(delta)
    return

  if crouch and not is_stuck:
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

func animate_swimming(delta, start) -> void:
  if start or (!start and $Sprite.animation != 'SwimmingLoop' and $Sprite.animation != 'SwimmingStart' and !is_on_floor()) and $Sprite.animation != 'Appearing':
    $Sprite.animation = 'SwimmingStart'
    $Sprite.frame = 0
    $Sprite.speed_scale = 1
  
  if $Sprite.frame > 5:
    $Sprite.animation = 'SwimmingLoop'
    $Sprite.frame = 0
    $Sprite.speed_scale = 2
  
  if velocity.x <= -8 * Global.get_delta(delta):
    $Sprite.flip_h = true
  if velocity.x >= 8 * Global.get_delta(delta):
    $Sprite.flip_h = false
    
  if launch_counter > 0:
    launch_counter -= 1.01 * Global.get_delta(delta)

  if crouch and not is_stuck:
    if Global.state > 0:
      animate_sprite('Crouching')
    else:
      animate_sprite('Stopped')
    return
  
  if $Sprite.animation == 'Walking':
    $Sprite.speed_scale = abs(velocity.x / 50) * 2.5 + 4
  
  if velocity.x <= -0.16 * Global.get_delta(delta):
    if (is_on_floor() or $Sprite.animation == 'Launching') and $Sprite.animation != 'Appearing':
      animate_sprite('Walking')

  if velocity.x >= 0.16 * Global.get_delta(delta):
    if (is_on_floor() or $Sprite.animation == 'Launching') and $Sprite.animation != 'Appearing':
      animate_sprite('Walking')

  if abs(velocity.x) < 0.08 and (is_on_floor() or is_over_platform()) and $Sprite.animation != 'Appearing' and $Sprite.animation != 'Launching':
    animate_sprite('Stopped')
  
  if appear_counter > 0:
    if not allow_custom_animation:
      if not $Sprite.animation == 'Appearing':
        animate_sprite('Appearing')
      $Sprite.speed_scale = 1
      
    appear_counter -= 1.5 * Global.get_delta(delta)
    if not shield_star: return
  if appear_counter < 0:
    appear_counter = 0
    $Sprite.animation = 'SwimmingStart'
    $Sprite.frame = 0
    $Sprite.speed_scale = 1

  if shield_counter > 0:
    shield_counter -= 1.5 * Global.get_delta(delta)
    if appear_counter == 0 and not shield_star:
      $Sprite.visible = int(shield_counter / 2) % 2 == 0
    if appear_counter > 0: return
  if shield_counter < 0:
    shield_counter = 0
    $Sprite.visible = true


func animate_climbing(delta) -> void:
  if velocity.x <= -8 * Global.get_delta(delta):
    $Sprite.flip_h = true
  if velocity.x >= 8 * Global.get_delta(delta):
    $Sprite.flip_h = false

  if appear_counter > 0:
    if not allow_custom_animation:
      if not $Sprite.animation == 'Appearing':
        animate_sprite('Appearing')
      $Sprite.speed_scale = 1
      
    appear_counter -= 1.5 * Global.get_delta(delta)
    return
  if appear_counter < 0:
    appear_counter = 0

  if shield_counter > 0:
    shield_counter -= 1.5 * Global.get_delta(delta)
    if appear_counter == 0:
      $Sprite.visible = int(shield_counter / 2) % 2 == 0
  if shield_counter < 0:
    shield_counter = 0
    $Sprite.visible = true

  if allow_custom_animation: return

  if launch_counter > 0:
    launch_counter -= 1.01 * Global.get_delta(delta)
  
  if $Sprite.animation == 'Climbing':
    $Sprite.speed_scale = 2 if abs(velocity.y + velocity.x) > 5 else 0
  else:
    animate_sprite('Climbing')

func animate_sprite(anim_name) -> void:
  $Sprite.set_animation(anim_name)

func update_collisions() -> void:
  $Collision.disabled = not (Global.state == 0 or crouch)
  $TopDetector/CollisionTop.disabled = not (Global.state == 0 or crouch)
  $InsideDetector/CollisionSmall.disabled = not (Global.state == 0 or crouch)
  $SmallRightDetector/CollisionSmallRight.disabled = not (Global.state == 0 or crouch)
  $SmallLeftDetector/CollisionSmallLeft.disabled = not (Global.state == 0 or crouch)
  
  $CollisionBig.disabled = not (Global.state > 0 and not crouch)
  $TopDetector/CollisionTopBig.disabled = not (Global.state > 0 and (not crouch or is_stuck))
  $InsideDetector/CollisionBig.disabled = not (Global.state > 0 and not crouch)
  $SmallRightDetector/CollisionSmallRightBig.disabled = not (Global.state > 0 and not crouch)
  $SmallLeftDetector/CollisionSmallLeftBig.disabled = not (Global.state > 0 and not crouch)

func one_tile_gap(vel: float) -> void:
  if (velocity.x > 1 or velocity.x < -1) and (vel > 1 or vel < -1):
    var pos = Vector2.ZERO
    
    if (ray_L.is_colliding() and !ray_R.is_colliding()):
      if ray_L.get_collision_point().y == round(position.y): return
      if ray_L_2.is_colliding(): return
      pos.y = ray_L.get_collision_point().y
      pos.x = position.x - 0.1
    if (ray_R.is_colliding() and !ray_L.is_colliding()):
      if ray_R.get_collision_point().y == round(position.y): return
      if ray_R_2.is_colliding(): return
      pos.y = ray_R.get_collision_point().y
      pos.x = position.x + 0.1
    
    if pos != Vector2.ZERO:
      position = pos
      velocity = Vector2(vel, 0)

func kill() -> void:
  dead = true
  $Sprite.visible = true

func unkill() -> void:
  dead = false
  $Collision.disabled = false
  $CollisionBig.disabled = false
  $BottomDetector/CollisionBottom.disabled = false
  $BottomDetector/CollisionBottom2.disabled = false
  $InsideDetector.collision_layer = 3
  $InsideDetector.collision_mask = 3
  dead_counter = 0
  dead_hasJumped = false
  appear_counter = 0
  shield_counter = 0
  $TopDetector/CollisionTop.disabled = false
  $BottomDetector/CollisionBottom.disabled = false
  $Sprite.position = Vector2.ZERO
  animate_sprite('Stopped')

func star_logic() -> void:
  var overlaps = $InsideDetector.get_overlapping_bodies()

  if overlaps.size() > 0:
    for i in range(overlaps.size()):
      if overlaps[i].is_in_group('Enemy') and overlaps[i].has_method('kill'):
        if overlaps[i].force_death_type == false:
          overlaps[i].kill(AliveObject.DEATH_TYPE.FALL, star_kill_count)
        else:
          overlaps[i].kill(overlaps[i].death_type, star_kill_count)
        if star_kill_count < 6:
          star_kill_count += 1
        else:
          star_kill_count = 0

func debug() -> void:
  if Input.is_action_just_pressed('mouse_middle'):
    $DebugText.visible = !$DebugText.visible

  $DebugText.text = 'x speed = ' + str(velocity.x) + '\ny speed = ' + str(velocity.y) + '\nanimation: ' + str($Sprite.animation).to_lower() + '\nmovement: ' + str(Movement.keys()[movement_type].to_lower()) + '\nfps: ' + str(Engine.get_frames_per_second())

func _process_debug_fly(delta: float) -> void:
  var debugspeed: int = 10 + (int(Input.is_action_pressed('mario_fire')) * 10) - (int( Input.is_action_pressed('debug_shift') ) * 9)
  if Input.is_action_pressed('mario_right'):
    position.x += debugspeed * Global.get_delta(delta)
  if Input.is_action_pressed('mario_left'):
    position.x -= debugspeed * Global.get_delta(delta)
  
  if Input.is_action_pressed('mario_up'):
    position.y -= debugspeed * Global.get_delta(delta)
  if Input.is_action_pressed('mario_crouch'):
    position.y += debugspeed * Global.get_delta(delta)
    
  if Input.is_action_just_pressed('debug_rotate_right'):
    target_gravity_angle += 45
    
  if Input.is_action_just_pressed('debug_rotate_left'):
    target_gravity_angle -= 45

func _process_camera(delta: float) -> void:
  if dead: return
  
  if sections_scroll:
    var base_y = floor((position.y + 240) / 960) * 960
    $Camera.limit_top = base_y
    $Camera.limit_bottom = base_y + 480
  
  if inited_camera_addon and inited_camera_addon.has_method('_process_camera'):
    inited_camera_addon._process_camera(self, delta)
  
  if 'sgr_scroll' in get_parent() and get_parent().sgr_scroll:
    var base_x = floor(position.x / 640) * 640
    $Camera.limit_left = base_x
    $Camera.limit_right = base_x + 640
    
func _physics_process(delta: float) -> void:
  if inited_camera_addon and inited_camera_addon.has_method('_process_physics_camera'):
    inited_camera_addon._process_physics_camera(self, delta)
  if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_process_mixin_physics') and not dead:
    ready_powerup_scripts[Global.state]._process_mixin_physics(self, delta)
