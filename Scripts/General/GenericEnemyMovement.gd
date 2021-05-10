extends KinematicBody2D
class_name GenericEnemyMovement

# AI Types
enum AI_TYPE {
  IDLE,
  WALK,
  FLY,
  FREE
}

enum DEATH_TYPE {
  BASIC,
  FALL
}

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()
var onScreen: bool

var velocity: Vector2

signal on_stomp

export var can_hurt: bool = true

export var dir: float = -1

export var speed: float = 50
export var smart_turn: bool
export var no_gravity: bool
export var is_stompable: bool
export var is_kickable: bool = true

export var sin_height: float = 20
export var sin_speed: float = 150
export var score: int = 100

export var alive: bool = true

export(AI_TYPE) var ai: int = AI_TYPE.IDLE
export(DEATH_TYPE) var death: int = DEATH_TYPE.BASIC

var death_complete: bool = false

func _ready() -> void:
  vis.process_parent = true
  vis.physics_process_parent = true
  vis.connect('screen_entered', self, '_on_screen_entered')
  vis.connect('screen_exited', self, '_on_screen_exited')
  
  add_child(vis)
  
  var feets = preload('res://Objects/Enemies/Core/Feets.tscn').instance()
  if smart_turn and ai == AI_TYPE.WALK:
    feets.connect('on_cliff', self, '_turn')
  
  $Sprite.flip_h = true
  
  self.add_child(feets)
  
  self.add_to_group('Enemy')

# _AI() function redirect to other AI functions
func _AI(delta: float) -> void:
  match ai:
    AI_TYPE.IDLE:
      IDLE_AI()
    AI_TYPE.WALK:
      WALK_AI()
    AI_TYPE.FLY:
      FLY_AI()
    AI_TYPE.FREE:
      FREE_AI()

func _process(delta) -> void:
  # Gravity
  if (!is_on_floor() and (death == DEATH_TYPE.BASIC or alive) and ai != AI_TYPE.FLY) or (not death == DEATH_TYPE.BASIC and not alive):
    velocity.y += Global.gravity * (1 if alive else 0.75) * Global.get_delta(delta)

  velocity = move_and_slide(velocity, Vector2.UP)

  if alive:
    _process_alive(delta)
  else:
    if death == DEATH_TYPE.BASIC:
      if not death_complete:
        _process_death()
      death_complete = true

func _process_alive(delta: float) -> void:
  _AI(delta)
  
  # Stomping
  var mario = get_parent().get_node('Mario')
  var mario_bd = mario.get_node('BottomDetector')
  var mario_pd = mario.get_node('InsideDetector')
  var pd_overlaps = mario_pd.get_overlapping_bodies()
  var bd_overlaps = mario_bd.get_overlapping_bodies()

  if bd_overlaps and bd_overlaps.has(self) and not (pd_overlaps and pd_overlaps.has(self)) and is_stompable:
    if Input.is_action_pressed('mario_jump'):
      mario.y_speed = -13
    else:
      mario.y_speed = -8
    mario.get_node('BaseSounds').get_node('ENEMY_Stomp').play()
    alive = false
    
    var score_text = ScoreText.new(score, position)
    get_parent().add_child(score_text)

  if pd_overlaps and pd_overlaps[0] == self and can_hurt:
    Global._ppd()
  
  # Kicking
  var g_overlaps = $Feets/Feet_M.get_overlapping_bodies()
  if g_overlaps and g_overlaps[0] is StaticBody2D and g_overlaps[0].triggered and g_overlaps[0].t_counter < 12 and is_kickable:
    kick()

func kick() -> void:
  death = DEATH_TYPE.FALL
  alive = false

  var score_text = ScoreText.new(100, position)
  get_parent().add_child(score_text)

  velocity.y = -180
  velocity.x = 0

  $Collision.shape = null
  $Sprite.set_animation('Falling')
  $Kick.play()

func _process_death() -> void:
  $Sprite.set_animation('Dead')
  match death:
    DEATH_TYPE.BASIC:
      velocity.x = 0
      collision_layer = 2
      collision_mask = 2
      yield(get_tree().create_timer(2.0), 'timeout')
      queue_free()

# Just standing AI
func IDLE_AI() -> void:
  velocity.x = 0

# Walking AI
func WALK_AI() -> void:
  velocity.x = speed * dir
  if is_on_wall():
    _turn()

# Flying AI
func FLY_AI() -> void:
  velocity.x = speed * dir
  velocity.y = (sin(position.x / sin_height) * sin_speed)
  if is_on_wall():
    _turn()

# Free move AI
func FREE_AI() -> void:
  pass

func _turn() -> void:
  $Sprite.flip_h = dir > 0
  velocity.x = -dir * speed * 2
  dir = -dir

func getInfo() -> String:
  return '{self}\nvel:{velocity}\nspeed:{speed}\nSmart:{smart_turn}\nCan stmpd:{is_stompable}\nDir:{dir}\nOn screen:{onScreen}'.format({ 'self': name, 'velocity': velocity,'speed': speed, 'smart_turn': smart_turn, 'is_stompable': is_stompable, 'dir': dir, 'onScreen': onScreen }).to_lower()

func _on_screen_entered() -> void:
  onScreen = true

func _on_screen_exited() -> void:
  if not alive:
    queue_free()
  onScreen = false

