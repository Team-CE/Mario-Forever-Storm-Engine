extends Node2D

export var set_level_id: int = 0
export var map_scene: String = ''

var win_music = preload('res://Music/1-music-complete-level.ogg')

var initial_position: float
var counter: float = 0

var crossed: bool = false

var bar_enabled: bool = false
var bar_accel: float = -6

var wait_counter: float = 30

func _ready() -> void:
  initial_position = $CrossingBar.position.y
  win_music.loop = false

func _process(delta) -> void:
  if not crossed:
    counter += 1 * Global.get_delta(delta)
    if counter < 75:
      $CrossingBar.position.y += 3 * Global.get_delta(delta)
    elif counter < 150:
      $CrossingBar.position.y -= 3 * Global.get_delta(delta)
    else:
      counter = 0
      $CrossingBar.position.y = initial_position
    
    if Global.Mario.get_node('InsideDetector').get_overlapping_areas().has($CrossingBar) or (Global.Mario.position.x >= position.x + 24 and Global.Mario.velocity.y == 0):
      if Global.Mario.get_node('InsideDetector').get_overlapping_areas().has($CrossingBar):
        bar_enabled = true
        $CrossingBar/Sprite.set_animation('crossed')
        var given_score: int
        var calculated_y: float = $CrossingBar.position.y - initial_position
        if calculated_y < 30:
          given_score = 10000
        elif calculated_y < 60:
          given_score = 5000
        elif calculated_y < 100:
          given_score = 2000
        elif calculated_y < 150:
          given_score = 1000
        elif calculated_y < 200:
          given_score = 500
        else:
          given_score = 200
        var score_text = ScoreText.new(given_score, Global.Mario.position)
        get_parent().add_child(score_text)
      else:
        var score_text = ScoreText.new(100, Global.Mario.position)
        get_parent().add_child(score_text)
      Global.level_ended = true
      crossed = true
      #MusicEngine.play_music('res://Music/1-music-complete-level.it')
      MusicPlayer.get_node('Main').stream = win_music
      MusicPlayer.get_node('Main').play()
      Global.checkpoint_active = 0
      Global.Mario.controls_enabled = false
      counter = 0
  else:
    counter += 1 * Global.get_delta(delta)
    Global.Mario.velocity.x = 150

    if bar_enabled:
      $CrossingBar.position.x -= 3 * Global.get_delta(delta)
      $CrossingBar.position.y += bar_accel * Global.get_delta(delta)
      bar_accel += 0.2 * Global.get_delta(delta)
      $CrossingBar.rotation_degrees += 17 * Global.get_delta(delta)

    if counter > 400:
      if Global.time > 0:
        Global.time -= round(5 * Global.get_delta(delta))
        Global.add_score(round(50 * Global.get_delta(delta)))
        Global.emit_signal('TimeTick')
        if not Global.HUD.get_node('ScoreSound').playing:
          Global.HUD.get_node('ScoreSound').play()
      elif Global.time <= 0:
        Global.time = 0
        Global.emit_signal('TimeTick')
        wait_counter -= 1 * Global.get_delta(delta)
        if wait_counter < 0:
          Global.levelID = set_level_id
          get_tree().change_scene(map_scene)
        
func act() -> void:
  Global.level_ended = true
  crossed = true
  #MusicEngine.play_music('res://Music/1-music-complete-level.it')
  MusicPlayer.get_node('Main').stream = win_music
  MusicPlayer.get_node('Main').play()
  Global.checkpoint_active = 0
  Global.Mario.controls_enabled = false
  counter = 0
