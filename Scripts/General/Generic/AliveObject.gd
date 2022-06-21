extends KinematicBody2D
class_name AliveObject, "res://GFX/Editor/AliveBody.png"

signal enemy_died

const multiplier_scores = [1, 2, 5, 10, 20, 50, 0.01]
const pitch_md = [1, 1.05, 1.1, 1.15, 1.20, 1.25, 1.30, 1.35]

enum DEATH_TYPE {
  BASIC,
  FALL,
  CUSTOM,
  NONE,
  DISAPPEAR,
  UNFREEZE
}

export var vars: Dictionary = {"speed":50.0, "bounce":9}
export var AI: Script

export var gravity_scale: float = 1
export var score: int           = 100
export var smart_turn: bool
export var invincible: bool
export var invincible_for_projectiles: Array = []
export(float,-1,1) var dir: float = -1
export var can_freeze: bool = false
export var frozen: bool = false
export var force_death_type: bool = false
export var auto_destroy: bool = true
export var death_signal_exception: bool = false

#RayCasts leave empty if smart_turn = false
export var ray_L_pth: NodePath
export var ray_R_pth: NodePath
export var sound_pth: NodePath
export var alt_sound_pth: NodePath
export var animated_sprite_pth: NodePath
export var frozen_sprite_pth: NodePath

var ray_L: RayCast2D
var ray_R: RayCast2D
var animated_sprite: AnimatedSprite
var frozen_sprite: AnimatedSprite
var sound: AudioStreamPlayer2D
var alt_sound: AudioStreamPlayer2D

var freeze_sound = preload('res://Sounds/Main/ice1.wav')
var unfreeze_sound = preload('res://Sounds/Main/ice2.wav')

var velocity: Vector2
var alive: bool = true
var death_type: int
var velocity_enabled: bool = true

var just_died: bool = false

onready var time = get_tree().create_timer(0)

onready var first_pos: Vector2 = position   # For pirahna plant and other enemies
onready var brain: Brain = Brain.new()      # Shell for AI

var rng = RandomNumberGenerator.new()

func _ready() -> void:
  rng.randomize()
  
  if ray_L_pth.is_empty() || ray_R_pth.is_empty(): # Ray casts init
    smart_turn = false
  else:
    ray_L = get_node(ray_L_pth)
    ray_R = get_node(ray_R_pth)
  
  if !sound_pth.is_empty():  # Sound player init
    sound = get_node(sound_pth)

  if !alt_sound_pth.is_empty():  # Alt sound player init
    alt_sound = get_node(alt_sound_pth)
    
  if animated_sprite_pth.is_empty():  # Animated sprite init
    push_warning('[CE WARNING] Cannot load Animated sprite at:' + str(self))
  else:
    animated_sprite = get_node(animated_sprite_pth)
    
  if !frozen_sprite_pth.is_empty():
    frozen_sprite = get_node(frozen_sprite_pth)
    
  if can_freeze:
    var ice1 = AudioStreamPlayer2D.new()
    var ice2 = AudioStreamPlayer2D.new()
    
    ice1.stream = freeze_sound
    ice2.stream = unfreeze_sound
    
    ice1.name = 'ice1'
    ice2.name = 'ice2'
    
    add_child(ice1)
    add_child(ice2)
  
  brain.name = 'Brain'  # Brain init
  add_child(brain)
  if AI != null:  # AI init
    brain.set_script(AI)
    brain._setup(self)
  else:
    printerr('[CE ERROR] AliveObject' + str(self) + ': No AI script assigned!')

  if brain.has_method('_ready_mixin'):
    brain._ready_mixin()

  if death_type == DEATH_TYPE.CUSTOM && !brain.has_method('_on_custom_death'):
    printerr('[CE ERROR] AliveObject' + str(self) + ': No custom death function provided.')
  
  if !death_signal_exception:
    connect('enemy_died', get_tree().get_current_scene(), 'activate_event', ['on_enemy_death', [get_name()]])

func _physics_process(delta:float) -> void:
  var vse = get_node_or_null("VisibilityEnabler2D")
  if is_instance_valid(vse):
    vse.scale = Vector2(5,5)
  if !alive && death_type != DEATH_TYPE.FALL && !force_death_type:
    return
  
  brain._ai_process(delta) #Calling brain cells
  
  if is_instance_valid(Global.Mario):
    if auto_destroy and (position.y > Global.Mario.get_node('Camera').limit_bottom + 32 and position.y < Global.Mario.get_node('Camera').limit_bottom + 200):
      queue_free()
  # Fixing ceiling collision and is_on_floor() flickering
  if (is_on_floor() || is_on_ceiling()) && alive && velocity.y >= 0:
    velocity.y = 1
  
  if velocity_enabled:
    velocity = move_and_slide(velocity.rotated(rotation), Vector2.UP.rotated(rotation)).rotated(-rotation)
    
  # Freeze
  if frozen_sprite && frozen:
    frozen_sprite.visible = true
    frozen_sprite.playing = true
    animated_sprite.playing = false

# Useful functions
func turn(mp:float = 1) -> void:
  dir = -dir
  velocity.x = vars["speed"] * mp * dir
  animated_sprite.flip_h = dir < 0

func on_edge() -> bool:
  return (ray_L.is_colliding() && !ray_R.is_colliding()) || (ray_R.is_colliding() && !ray_L.is_colliding())

# warning-ignore:shadowed_variable
func kill(death_type: int = 0, score_mp: int = 0, csound = null, projectile = null) -> void:
  if invincible:
    return
  if projectile: 
    for proj_exception in invincible_for_projectiles:
      if proj_exception.to_lower() in projectile.to_lower():
        return
  if not force_death_type:
    alive = false
    collision_layer = 0
    collision_mask = 0
    velocity.x = rng.randf_range(-50, 50)
    gravity_scale = 0.4
  if self.death_type != DEATH_TYPE.UNFREEZE:
    self.death_type = death_type
  if brain.has_method('_on_any_death'):
    brain._on_any_death()
  match self.death_type:       # TEMP
    DEATH_TYPE.BASIC:
      if !csound:
        sound.play()
      else:
        csound.play()
      animated_sprite.set_animation('dead')
      get_parent().add_child(ScoreText.new(score, position))
      time = get_tree().create_timer(4.0, false)
      time.connect('timeout', self, 'instance_free')
    DEATH_TYPE.DISAPPEAR:
      queue_free()
    DEATH_TYPE.FALL:
      if !csound:
        alt_sound.play()
      else:
        csound.play()
      if score_mp > len(multiplier_scores) - 1:
        score_mp = 0
      if score_mp == 6:
        Global.add_lives(1, false)
      get_parent().add_child(ScoreText.new(score * multiplier_scores[score_mp], position))
      z_index = 10
      velocity.y = -180
      animated_sprite.set_animation('falling')
      animated_sprite.rotation_degrees = rotation_degrees
      rotation_degrees = 0
      time = get_tree().create_timer(2.0, false)
      time.connect('timeout', self, 'instance_free')
    DEATH_TYPE.CUSTOM:
      if brain.has_method('_on_custom_death'):
        brain._on_custom_death()
    DEATH_TYPE.UNFREEZE:
      visible = false
      if $Collision: $Collision.disabled = true
      if $CollisionShape2D: $CollisionShape2D.disabled = true
      if $KillDetector/Collision: $KillDetector/Collision.disabled = true
      get_node('ice2').play()
      var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
      for i in range(4):
        var debris_effect = BrickEffect.new(position + Vector2(0, -16), speeds[i], 1)
        get_parent().add_child(debris_effect)
      time = get_tree().create_timer(2.0, false)
      time.connect('timeout', self, 'instance_free')
  just_died = true
  if !death_signal_exception: emit_signal('enemy_died')
  yield(get_tree(), 'idle_frame')
  just_died = false
        
func freeze() -> void:
  if !can_freeze || frozen:
    return
    
  get_node('ice1').play()
  
  frozen = true
  collision_layer = 3
  collision_mask = 3
  
  death_type = DEATH_TYPE.UNFREEZE
  animated_sprite.playing = false
  
func instance_free():
  queue_free()

func getInfo() -> String:
  return 'name: {n}\nvel x: {x}\nvel y: {y}'.format({'x':velocity.x,'y':velocity.y,'n':self.get_name()}).to_lower()
