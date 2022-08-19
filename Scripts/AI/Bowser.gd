extends Brain

var flame = preload('res://Objects/Enemies/BowserFlame.tscn')

var counter: float = 0
var move_multiplier: float = 0

var sequence: int = 0
var throw_activated: bool = false
var ccounter: int = 0
var cringecounter: float = 0
var hammer_fire: bool = false
var hammers_left: int = 0
var inited_throwable

var invis_c: float = 0
var mario_shift: float = 0
var lives: int = 8
var fireball_lives: int = 0
var initial_pos: Vector2
var modul_switch: bool = false

var fc: float = 0
var s_played: bool = false
var y_speed: float = 0
var f_act: bool = false

var rng
var camera

func _ready_mixin() -> void:
  owner.death_type = AliveObject.DEATH_TYPE.CUSTOM
  rng = RandomNumberGenerator.new()
  rng.randomize()
  if 'lives' in owner.vars:
    lives = owner.vars['lives']

  yield(owner.get_tree(), 'idle_frame')
  camera = Global.current_camera
  
func _setup(b) -> void:
  ._setup(b)
  initial_pos = owner.position + Vector2(-128, 0)
  inited_throwable = owner.vars['throw_script'].new()

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  if !owner.get_node('VisibilityNotifier2D').is_on_screen() and owner.alive:
    return
  
  # Bowser Lives counter
  var bowl = Global.current_scene.get_node('BowserLives/AnimatedSprite')
  if bowl.position.y < 80:
    bowl.position.y += 4
  
  # Death sequence
  if !owner.alive:
    owner.animated_sprite.animation = 'falling'
    owner.velocity.x = 0
    fc += 1 * Global.get_delta(delta)
    
    # Falling
    if fc > 100:
      y_speed += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
      owner.position.y += y_speed * delta
      owner.get_node('CollisionShape2D').disabled = true
      if !s_played:
        s_played = true
        owner.get_node('Fall').play()
    else:
      owner.velocity.y = 0
    
    # The end; winning
    if owner.global_position.y > camera.limit_bottom and !f_act:
      Global.current_scene.get_node('FinishLine').act()
      #todo the lava love animation
      f_act = true
      print('fell')
    return
  
  # Jumping gravity and animation
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    if (owner.velocity.y < 0 or owner.velocity.y > 10) and owner.animated_sprite.animation == 'walk':
      owner.animated_sprite.animation = 'jump'
  elif owner.animated_sprite.animation == 'jump':
    owner.animated_sprite.animation = 'walk'
  
  # Movement
  if move_multiplier > 0:
    owner.velocity.x = owner.vars["speed"] * owner.dir if !hammer_fire else 0
    move_multiplier -= 1 * Global.get_delta(delta)
  else:
    owner.velocity.x = 0
  
  # Invincibility blinking
  if invis_c > 0:
    invis_c -= 1 * Global.get_delta(delta)
    
    owner.animated_sprite.modulate.a += (-0.05 if !modul_switch else 0.05) * Global.get_delta(delta)
    if !modul_switch and owner.animated_sprite.modulate.a <= 0:
      modul_switch = true
    if modul_switch and owner.animated_sprite.modulate.a >= 1:
      modul_switch = false
  else:
    owner.animated_sprite.modulate.a = 1
  
  # Mario shift after stomping
  if mario_shift > 0:
    mario_shift -= 1 * Global.get_delta(delta)
  elif mario_shift < 0:
    mario_shift += 1 * Global.get_delta(delta)
    
  if mario_shift < 1 * Global.get_delta(delta) and mario_shift > -1 * Global.get_delta(delta):
    mario_shift = 0
  
  # Prevent from shifting when not needed
  if !Global.Mario.dead and !Global.Mario.is_on_wall():
    Global.Mario.position.x += mario_shift * Global.get_delta(delta)
  
  attack_logic(delta)
  
  # Movement limitation
  if abs((initial_pos - owner.position).x) > 224:
    owner.turn()
  
  # Direction
  owner.animated_sprite.flip_h = owner.global_position.x > Global.Mario.position.x
  
  # Stomping and hurting Mario
  if is_mario_collide('BottomDetector') and Global.Mario.velocity.y > 0 and invis_c <= 20:
    Global.Mario.velocity.y = -owner.vars["bounce"] * 50
    mario_shift = 10 if Global.Mario.velocity.x > 0 else -10
    bowser_damage()
  elif on_mario_collide('InsideDetector') and invis_c < 115:
    Global._ppd()
  
  # Lives counter update
  bowl.frame = lives
  
func attack_logic(delta: float) -> void:
  # Restoring animation after flame launch
  if owner.animated_sprite.animation == 'holding' and owner.animated_sprite.frame > 9:
    owner.animated_sprite.animation = 'walk'
  
  # Repeating pattern
  if sequence >= owner.vars['attack sequence'].size():
    sequence = 0
  
  if counter < 50:
    counter += 1 * Global.get_delta(delta)
  else:
    counter = 0
    move_multiplier = rng.randi_range(0, 64)
  
  if cringecounter < 5:
    cringecounter += 1 * Global.get_delta(delta)
  else:
    cringecounter = 0
    ccounter += 1
    # Jumping
    if rng.randi_range(0, 19) == 10 and owner.is_on_floor() and owner.global_position.y > camera.limit_top:
      owner.velocity.y = owner.vars['jump strength']
    
    # Attack Sequences
    match owner.vars['attack sequence'][sequence]:
      'triple':
        if ccounter % owner.vars['fire delay'] == 0 and !throw_activated:
          throw_activated = true
          owner.animated_sprite.animation = 'triple'
          owner.animated_sprite.frame = 0
          ccounter = 0
          return
      'hammer':
        hammer_fire = true
        if hammers_left == 0 and ccounter % owner.vars['hammer duration'] == 0:
          sequence += 1
          if sequence < owner.vars['attack sequence'].size() and owner.vars['attack sequence'][sequence] == 'hammer':
            hammers_left = owner.vars['hammer count']
        owner.animated_sprite.animation = 'hammer idle' if hammers_left == 0 else 'hammer fire'
        if hammers_left > 0 and ccounter % owner.vars['hammer interval'] == 0:
          hammers_left -= 1
          inited_throwable.throw(self)
        return
      _:
        if ccounter % owner.vars['fire delay'] == 0:
          throw_activated = true
          owner.animated_sprite.animation = 'holding'
          owner.animated_sprite.frame = 0
          ccounter = 0
    
    # Called when it's not hammer sequence
    if hammer_fire:
      hammer_fire = false
      hammers_left = 0
      owner.animated_sprite.animation = 'walk'
    
    # Triple flame
    if throw_activated and owner.animated_sprite.animation == 'triple' and ccounter % 12 == 0:
      owner.animated_sprite.animation = 'walk'
      owner.animated_sprite.frame = 0
      ccounter = 0
      for i in range(3):
        var fl = launch_flame()
        fl.rand_y = i - 1
      sequence += 1
      throw_activated = false
      return
  
  # Single flame
  if throw_activated and owner.animated_sprite.frame > 8:
# warning-ignore:return_value_discarded
    launch_flame()
    sequence += 1

func launch_flame() -> Node2D:
  owner.get_node('Throw').play()
  throw_activated = false
  var throwable = flame.instance()
  throwable.global_position = owner.global_position + Vector2(0, -40)
  throwable.target_pos_y = owner.vars['flame_pos']
  throwable.velocity.x = owner.vars['flame speed'] if !owner.animated_sprite.flip_h else -owner.vars['flame speed']
  Global.current_scene.add_child(throwable)
  return throwable

func bowser_damage() -> void:
  owner.animated_sprite.modulate.a = 1
  invis_c = 120
  owner.get_node('Hit').play()
  lives -= 1
  fireball_lives = 0
  if lives <= 0:
    owner.alive = false
    owner.get_node('Kill').play()
    MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 3.0)
    owner.velocity = Vector2.ZERO

func _on_custom_death(_score_mp):
  if invis_c > 20: return
  owner.alt_sound.play()
  if fireball_lives < 4:
    fireball_lives += 1
  else:
    bowser_damage()
