extends Node

var GameName = "CloudEngine"
var soundBar: float = 0                      # Game options
var musicBar: float = 0
var effects: bool = true
var scroll: int = 0
var vsync: bool = false
var rpc: bool = false

var toSaveInfo = {
  "SoundVol": soundBar,
  "MusicVol": musicBar,
  "Efekty": effects,
  "Scroll": scroll,
  "VSync": vsync,
  "RPC": rpc,
  "Controls": [
    '',
    '',
    '',
    '',
    '',
    ''
  ]
}

var gravity: float = 20                      # Global gravity

var HUD: CanvasLayer                         # ref HUD
var Mario: Node2D                            # ref Mario

signal TimeTick                              # Called when time got lower
signal OnPlayerLoseLife                      # Called when Player Die
signal OnScoreChange                         # Called when score get changed
signal OnLivesAdded                          # Called when Live added
signal OnCoinCollected                       # Called when coins collected

var lives: int = 4                           # Player lives
var time: int = 999                          # Time left
var score: int = 0                           # Score
var coins: int = 0                           # Player coins
var state: int = 0                           # Player powerup state

var projectiles_count: int = 0               # Self explanable

var debug: bool = false                      # Debug

var player_dead: bool = false
var level_ended: bool = false
var currlevel :Node2D

onready var timer: Timer = Timer.new()      # Create a new timer for delay

static func get_delta(delta) -> float: # Delta by 50 FPS
  return 50 / (1 / (delta if not delta == 0 else 0.0001))

static func get_vector_delta(delta) -> Vector2: # Vector2 with delta values
  return Vector2(get_delta(delta), get_delta(delta))

func _ready() -> void:
  if debug:
    add_child(preload('res://Objects/Core/Inspector.tscn').instance()) # Adding a debug inspector
  timer.wait_time = 1.45
  add_child(timer)
  
  toSaveInfo = JSON.parse(loadInfo()).result
  
  if !toSaveInfo:
    return
  soundBar = toSaveInfo.SoundVol
  musicBar = toSaveInfo.MusicVol
  effects = toSaveInfo.Efekty
  scroll = toSaveInfo.Scroll
  vsync = toSaveInfo.VSync
  rpc = toSaveInfo.RPC
  #MusicEngine.set_volume(musicBar)

func saveInfo(content):
    var file = File.new()
    file.open("user://" + GameName + ".cloudsav", File.WRITE)
    file.store_string(content)
    file.close()

func loadInfo():
    var file = File.new()
    file.open("user://" + GameName + ".cloudsav", File.READ)
    var content = file.get_as_text()
    file.close()
    return content

func _reset() -> void:   # Level Restart
  lives -= 1
  player_dead = false
# warning-ignore:return_value_discarded
  get_tree().reload_current_scene()

# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
  if timer.time_left <= 1 && time != -1: # Wait for delaying
    _delay()
    timer.start()
  if projectiles_count < 0:
    projectiles_count = 0
  
  # Hotkey for restarting current level
  if Input.is_action_pressed('debug_shift') and debug:
    if Input.is_action_just_pressed('debug_f2'):
      lives += 1
      _reset()

# warning-ignore:shadowed_variable
func add_score(score: int) -> void:
# warning-ignore:narrowing_conversion
  self.score += abs(score)
  HUD.get_node('Score').text = str(self.score)
  emit_signal('OnScoreChange')

# warning-ignore:shadowed_variable
func add_lives(lives: int, create_scoretext: bool) -> void:
  var scorePos = Mario.position
  scorePos.y -= 32
  if create_scoretext:
    var ScoreT = ScoreText.new(1, scorePos)
    Mario.get_parent().add_child(ScoreT)
# warning-ignore:narrowing_conversion
  self.lives += abs(lives)
  HUD.get_node('LifeSound').play()
  HUD.get_node('Lives').text = str(self.lives)
  emit_signal('OnLivesAdded')

# warning-ignore:shadowed_variable
func add_coins(coins: int) -> void:
# warning-ignore:narrowing_conversion
  self.coins += abs(coins)
  if self.coins >= 100:
    add_lives(1, true)
    self.coins = 0
  HUD.get_node('Coins').text = str(self.coins)
  emit_signal('OnCoinCollected')

func play_base_sound(sound: String) -> void:
  Mario.get_node('BaseSounds').get_node(sound).play()

func _ppd() -> void: # Player Powerdown
  if Mario.shield_counter > 0:
    return

  if state == 0:
    _pll()
  else:
    play_base_sound('MAIN_Pipe')
    if state > 1:
      state = 1
    else:
      state = 0
    Mario.appear_counter = 60
    Mario.shield_counter = 100

func _pll() -> void: # Player Death
  if player_dead:
    return
  player_dead = true
  emit_signal('OnPlayerLoseLife')
  MusicEngine.play_music('res://Music/1-music-die.it')
  Mario.dead = true

func _delay() -> void:
  if !is_instance_valid(Mario):
    return
  if !Mario.dead and Mario.controls_enabled:
    emit_signal('TimeTick')
    time -= 1
    if time == -1:
      _pll()

# Generic Functions

func enemy_bounce() -> void:
  if Input.is_action_pressed('mario_jump'):
    Mario.y_speed = -14
  else:
    Mario.y_speed = -9

func lerpa(a, b, t):
  return a - t * (b - a)
