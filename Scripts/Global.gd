extends Node

var GameName = "CloudEngine"
var soundBar: float = 0                      # Game options
var musicBar: float = 0
var effects: bool = true
var scroll: int = 0
var quality: int = 2
var scaling: bool = false
var controls: Dictionary

var toSaveInfo = {
  "SoundVol": soundBar,
  "MusicVol": musicBar,
  "Efekty": effects,
  "Scroll": scroll,
  "Quality": quality,
  "Scaling": scaling,
  "Controls": controls
}
var restartNeeded: bool = false

var gravity: float = 20                      # Global gravity

var HUD: CanvasLayer                         # ref HUD
var Mario: Node2D                            # ref Mario

signal TimeTick                              # Called when time ticks
signal OnPlayerLoseLife                      # Called when the player dies
signal OnScoreChange                         # Called when score gets changed
signal OnLivesAdded                          # Called when a life gets added
signal OnCoinCollected                       # Called when coins get collected

var lives: int = 4                           # Player lives
var time: int = 999                          # Time left
var score: int = 0                           # Score
var coins: int = 0                           # Player coins
var deaths: int = 0                          # Player deaths (for precision madness-like levels)
var state: int = 0                           # Player powerup state

var projectiles_count: int = 0               # Number of player's projectiles on screen

var checkpoint_active: int = 0               # Self explanable
var checkpoint_position: Vector2

var debug: bool = true                       # Debug
var debug_fly: bool = false
var debug_inv: bool = false

var level_ended: bool = false
var currlevel: Node2D

var levelID: int = 0

onready var timer: Timer = Timer.new()       # Create a new timer for delay

static func get_delta(delta) -> float:       # Delta by 50 FPS
  return 50 / (1 / (delta if not delta == 0 else 0.0001))

static func get_vector_delta(delta) -> Vector2: # Vector2 with delta values
  return Vector2(get_delta(delta), get_delta(delta))

func _ready() -> void:
  if debug:
    add_child(preload('res://Objects/Core/Inspector.tscn').instance()) # Adding a debug inspector
  timer.wait_time = 1.45
  add_child(timer)
  
  toSaveInfo = JSON.parse(loadInfo()).result # Loading settings
    
  if !toSaveInfo:
    return
  if toSaveInfo.has('SoundVol'): soundBar = toSaveInfo.SoundVol
  if toSaveInfo.has('MusicVol'): musicBar = toSaveInfo.MusicVol
  if toSaveInfo.has('Efekty'): effects = toSaveInfo.Efekty
  if toSaveInfo.has('Scroll'): scroll = toSaveInfo.Scroll
  if toSaveInfo.has('Quality'): quality = toSaveInfo.Quality
  if toSaveInfo.has('Scaling'): scaling = toSaveInfo.Scaling
  if toSaveInfo.has('Controls'): controls = toSaveInfo.Controls
  
  for action in controls: # Loading controls
    if controls[action] and controls[action] is String:
      var scancode = OS.find_scancode_from_string(controls[action])
      var key = InputEventKey.new()
      key.scancode = scancode
      if key is InputEventKey:
        var oldKeys = InputMap.get_action_list(action)
        for toRemove in oldKeys:
          if toRemove is InputEventKey:
            InputMap.action_erase_event(action, toRemove)
        InputMap.action_add_event(action, key)
  
  #MusicEngine.set_volume(musicBar)
  yield(get_tree(), 'idle_frame')
  if musicBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(musicBar / 5))
  if musicBar == -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), soundBar / 5)

func saveInfo(content):
  var file = File.new()
  
  file.open("user://" + GameName + ".cloudsav", File.WRITE)
  file.store_string(content)
  file.close()
  
  if scaling and ProjectSettings.get_setting("display/window/stretch/mode") == "2d":
    ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
    ProjectSettings.save_custom("override.cfg")
    restartNeeded = true
    print('Need to restart')
    
  elif not scaling and ProjectSettings.get_setting("display/window/stretch/mode") == "viewport":
    ProjectSettings.set_setting("display/window/stretch/mode", "2d")
    ProjectSettings.save_custom("override.cfg")
    restartNeeded = true
    print('Need to restart')

func loadInfo():
  var file = File.new()
  file.open("user://" + GameName + ".cloudsav", File.READ)
  var content = file.get_as_text()
  file.close()
  return content

func _reset() -> void:   # Level Restart
  lives -= 1
  if Mario:
    Mario.dead = false
  projectiles_count = 0
# warning-ignore:return_value_discarded
  get_tree().reload_current_scene()

# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
  if timer.time_left <= 1 && time != -1: # Wait for delaying
    _delay()
    timer.start()
  if projectiles_count < 0:
    projectiles_count = 0
  
  if Input.is_action_pressed('debug_shift') and debug:
  # Hotkey for restarting current level
    if Input.is_action_just_pressed('debug_f2'):
      lives += 1
      _reset()
      
  # Toggle fly mode
    if Input.is_action_just_pressed('debug_1'):
      if Mario.dead_gameover: return
      Mario.get_node('Sprite').modulate.a = 0.5 * (1 + int(debug_fly))
      debug_fly = !debug_fly
      if debug_inv and debug_fly:
        debug_inv = false
      if Mario.dead:
        Mario.unkill()
      play_base_sound('DEBUG_Toggle')
      
  # Toggle invisible mode
    if Input.is_action_just_pressed('debug_2'):
      debug_inv = !debug_inv
      if debug_inv and debug_fly:
        debug_fly = false
      play_base_sound('DEBUG_Toggle')
    
    if Input.is_action_just_pressed('debug_straylist'):
      if Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) > 0:
        print('[CE OUTPUT]: --- STRAY NODES LIST ---')
        print_stray_nodes()
      else:
        print('[CE OUTPUT]: No stray nodes yet, we\'re fine!')
      
# Debug powerups
func _input(ev):
  if !Input.is_action_pressed('debug_shift') and debug:
    if ev is InputEventKey and ev.scancode >= 48 and ev.scancode <= 57 and !ev.echo and ev.pressed:
      play_base_sound('DEBUG_Toggle')
      state = ev.scancode - 49
      Mario.appear_counter = 60
  
  if ev.is_action_pressed('ui_fullscreen'):
    OS.window_fullscreen = !OS.window_fullscreen
      
# fix physics fps issues
func _process(delta: float):
  var temp = round((1 / delta) / 60) * 60
  if temp > 0:
    Engine.iterations_per_second = temp
  
  # in case something goes wrong with volume
  if AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')) > 1:
    push_warning('Too high music volume!')
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), 0)

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
  if Mario.shield_counter > 0 or debug_inv or debug_fly:
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
  if Mario.dead or debug_inv or debug_fly:
    return
  emit_signal('OnPlayerLoseLife')
  if not Mario.custom_die_stream:
    MusicPlayer.get_node('Main').stream = Mario.die_music
    MusicPlayer.get_node('Main').play()
    MusicPlayer.get_node('Star').stop()
  else:
    var dieMusPlayer = AudioStreamPlayer.new()
    dieMusPlayer.set_stream(Mario.custom_die_stream)
    add_child(dieMusPlayer)
    dieMusPlayer.play()
    
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
  
func is_mario_collide(_detector_name: String, obj) -> bool:
  var collisions = Mario.get_node_or_null(_detector_name).get_overlapping_bodies()
  return collisions && collisions.has(obj)
  
func is_mario_collide_area(_detector_name: String, obj) -> bool:
  var collisions = Mario.get_node_or_null(_detector_name).get_overlapping_areas()
  return collisions && collisions.has(obj)
 
func is_getting_closer(pix: float, pos: Vector2) -> bool:
  var camera = Mario.get_node_or_null('Camera')
  return (
    pos.x > camera.global_position.x - 320 + pix and
    pos.x < camera.global_position.x + 320 - pix and
    pos.y > camera.global_position.y - 320 + pix and
    pos.y < camera.global_position.y + 320 - pix
  )
