extends KinematicBody2D
class_name GenericEnemyMovement

# AI Types
enum AI_TYPE {
  IDLE,
  WALK,
  FLY,
  PIRANHA,
  PIRANHA_UPSIDE_DOWN
}

enum DEATH_TYPE {
  BASIC,
  FALL,
  SHELL,            # Requires "Shell Stopped" and "Shell Moving" animations.
  DISAPPEAR
}

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()
var onScreen: bool

var velocity: Vector2

signal on_stomp

export var can_hurt: bool = true

export var dir: float = -1

export var speed: float = 50
export var shell_speed: float = 250
export var smart_turn: bool
export var no_gravity: bool
export var is_stompable: bool
export var is_kickable: bool = true

export var sin_height: float = 20
export var sin_speed: float = 150
export var score: int = 100

export var alive: bool = true
export var active: bool = true

export(AI_TYPE) var ai: int = AI_TYPE.IDLE
export(DEATH_TYPE) var death: int = DEATH_TYPE.BASIC

export var appearing: bool = false
var appear_counter: float = 0
var appeared: bool = false

var death_complete: bool = false

var old_speed: float

var is_shell: bool = false
var shell_moving: bool = true
var shell_counter: float = 0
var skip_dir_change: bool = false
var shell_score_multiplier: float = 0

var initial_y: float = 0
var piranha_counter: float = 0
var no_velocity: bool = false

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

  old_speed = speed
  initial_y = position.y + 59

# _AI() function redirect to other AI functions
func _AI(delta: float) -> void:
  match ai:
    AI_TYPE.IDLE:
      IDLE_AI()
    AI_TYPE.WALK:
      WALK_AI()
    AI_TYPE.FLY:
      FLY_AI()
    AI_TYPE.PIRANHA:
      PIRANHA_AI(delta, false)
    AI_TYPE.FREE:
      FREE_AI()

func _physics_process(delta):
  skip_dir_change = false

  if alive:
    _AI(delta)

  if appearing and appear_counter < 32:
    active = false
    position.y -= 0.5 * Global.get_delta(delta)
    appear_counter += 0.5 * Global.get_delta(delta)
    no_gravity = true
    velocity.y = 0
    $Collision.disabled = true
    appeared = true
  elif appeared:
    active = true
    appearing = false
    if old_speed != -99:
      speed = old_speed
      old_speed = -99
    ai = AI_TYPE.WALK
    no_gravity = false
    $Collision.disabled = false
    z_index = 0
  
  if is_shell and alive:
    old_speed = shell_speed
    if not shell_moving:
      shell_score_multiplier = 0
      speed = 0
      $Sprite.set_animation('Shell Stopped')
    else:
      speed = shell_speed
      $Sprite.set_animation('Shell Moving')

  if not active:
    return
  # Gravity
  if (!is_on_floor() and (death == DEATH_TYPE.BASIC or alive) and ai != AI_TYPE.FLY) or (not death == DEATH_TYPE.BASIC and not alive):
    velocity.y += Global.gravity * (1 if alive else 0.4) * Global.get_delta(delta)

  if not no_velocity:
    velocity = move_and_slide(velocity, Vector2.UP)


func _process(delta) -> void:
  if alive:
    _process_alive(delta)
  else:
    if death == DEATH_TYPE.BASIC:
      if not death_complete:
        _process_death()
      death_complete = true

func _process_alive(delta: float) -> void:
  # Stomping
  var mario_bd = Global.Mario.get_node('BottomDetector')
  var mario_pd = Global.Mario.get_node('InsideDetector')
  var pd_overlaps = mario_pd.get_overlapping_bodies()
  var bd_overlaps = mario_bd.get_overlapping_bodies()

  if ((not (is_shell and not shell_moving) and (bd_overlaps and bd_overlaps.has(self) and not (pd_overlaps and pd_overlaps.has(self)))) or ((is_shell and not shell_moving) and (pd_overlaps and pd_overlaps.has(self)))) and is_stompable and Global.Mario.y_speed >= 0 and shell_counter > 10:
    if death == DEATH_TYPE.BASIC or (death == DEATH_TYPE.SHELL and shell_moving) or (death == DEATH_TYPE.SHELL and not is_shell):
      if Input.is_action_pressed('mario_jump'):
        Global.Mario.y_speed = -14
      else:
        Global.Mario.y_speed = -9
      Global.play_base_sound('ENEMY_Stomp')
    elif is_shell and not shell_moving:
      $Kick.play()
    if death == DEATH_TYPE.BASIC:
      alive = false
    else:
      shell_moving = !shell_moving
      is_shell = true
      if Global.Mario.position.x > position.x:
        dir = -1
      else:
        dir = 1
    shell_counter = 0
    
    if not (shell_moving and is_shell):
      var score_text = ScoreText.new(score, position)
      get_parent().add_child(score_text)

  if pd_overlaps and pd_overlaps[0] == self and can_hurt and shell_counter > 30 and not (is_shell and not shell_moving):
    Global._ppd()

  if shell_counter < 31:
    shell_counter += 1 * Global.get_delta(delta)
  
  # Kicking
  var g_overlaps = $Feets/Feet_M.get_overlapping_bodies()
  if g_overlaps and g_overlaps[0] is StaticBody2D and g_overlaps[0].triggered and g_overlaps[0].t_counter < 12 and is_kickable:
    kick(0)

func kick(score_multiplier: float) -> void:
  if death == DEATH_TYPE.BASIC:
    death = DEATH_TYPE.FALL
  alive = false

  var multiplier_scores = [100, 200, 500, 1000, 2000, 5000, 1]

  var score_text = ScoreText.new(multiplier_scores[score_multiplier], position)
  get_parent().add_child(score_text)

  if score_multiplier == 6:
    Global.add_lives(1, false)

  velocity.y = -180
  velocity.x = 0

  $Collision.shape = null
  $Sprite.set_animation('Falling')
  $Kick.play()
  if death == DEATH_TYPE.DISAPPEAR:
    $Sprite.visible = false
    yield(get_tree().create_timer(2.0), 'timeout')
    queue_free()


func _process_death() -> void:
  $Sprite.set_animation('Dead')
  match death:
    DEATH_TYPE.BASIC:
      velocity.x = 0
      collision_layer = 2
      collision_mask = 2
      yield(get_tree().create_timer(2.0), 'timeout')
      queue_free()

# Standing AI
func IDLE_AI() -> void:
  velocity.x = 0

# Walking AI
func WALK_AI() -> void:
  # Moving shell
  if shell_moving and is_shell:
    var overlaps = get_node('KillDetector').get_overlapping_bodies()

    if overlaps.size() > 0:
      for i in range(overlaps.size()):
        if overlaps[i].is_in_group('Enemy') and overlaps[i].is_kickable and not overlaps[i] == self:
          if overlaps[i].death == DEATH_TYPE.SHELL and overlaps[i].shell_moving and overlaps[i].is_shell:
            kick(0)
            overlaps[i].kick(0)
            shell_speed = 0
            speed = 0
          else:
            overlaps[i].kick(shell_score_multiplier)
          skip_dir_change = true
          shell_score_multiplier += 1
          if shell_score_multiplier >= 7:
            shell_score_multiplier = 0
  
  # Direction change
  velocity.x = speed * dir
  if is_on_wall() and not skip_dir_change:
    _turn()

# Flying AI
func FLY_AI() -> void:
  velocity.x = speed * dir
  velocity.y = (sin(position.x / sin_height) * sin_speed)
  if is_on_wall():
    _turn()

func PIRANHA_AI(delta: float, reversed: bool) -> void:
  active = true
  no_gravity = true
  no_velocity = true
  velocity.y = 0

  if piranha_counter == 0:
    position.y = initial_y

  piranha_counter += 1 * Global.get_delta(delta)

  if piranha_counter < 60:
    position.y -= 1 * (-1 if reversed else 1) * Global.get_delta(delta)
  
  if piranha_counter >= 130 and piranha_counter < 190:
    position.y += 1 * (-1 if reversed else 1) * Global.get_delta(delta)
  
  if piranha_counter >= 260 and (Global.Mario.position.x < position.x - 80 or Global.Mario.position.x > position.x + 80):
    piranha_counter = 0

# Free move AI
func FREE_AI() -> void:
  pass

func _turn() -> void:
  $Sprite.flip_h = dir > 0
  velocity.x = -dir * speed
  dir = -dir

func getInfo() -> String:
  return '{self}\nvel:{velocity}\nspeed:{speed}\nSmart:{smart_turn}\nCan stmpd:{is_stompable}\nDir:{dir}\nOn screen:{onScreen}'.format({ 'self': name, 'velocity': velocity,'speed': speed, 'smart_turn': smart_turn, 'is_stompable': is_stompable, 'dir': dir, 'onScreen': onScreen }).to_lower()

func _on_screen_entered() -> void:
  onScreen = true

func _on_screen_exited() -> void:
  if not alive:
    queue_free()

