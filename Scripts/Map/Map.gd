extends Node2D

var internal_offset: float = 0

export var music: Resource
export var mario_speed: float = 1
export var mario_fast_speed: float = 15
export var stop_points: Array = []
export var level_scenes: Array = []

var current_speed: float = mario_speed
var stopped: bool = false

var fading_out: bool = false
var circle_size: float = 0.623

onready var cam = $MarioPath/PathFollow2D/MiniMario/Camera2D

func _ready() -> void:
  MusicPlayer.stream = music
  MusicPlayer.play()
  
  if Global.levelID > 0:
    $MarioPath/PathFollow2D.offset = stop_points[Global.levelID - 1]

func _process(delta: float) -> void:
  $MarioPath/PathFollow2D/MiniMario/AnimatedSprite.speed_scale = 20 if !stopped else 5

  if $MarioPath/PathFollow2D.offset < stop_points[Global.levelID]:
    $MarioPath/PathFollow2D.offset += current_speed * Global.get_delta(delta)
    
    if Input.is_action_just_pressed('mario_jump'):
      current_speed = mario_fast_speed

  if $MarioPath/PathFollow2D.offset > stop_points[Global.levelID]:
    $MarioPath/PathFollow2D.offset = stop_points[Global.levelID]
    stopped = true
    
  if stopped and not fading_out:
    _process_camera(delta)
    var pj = $ParallaxBackground/ParallaxLayer/PressJump
    if pj.modulate.a < 1:
      pj.modulate.a += 0.1 * Global.get_delta(delta)
    else:
      pj.modulate.a = 1

  if Input.is_action_just_pressed('mario_jump') and !fading_out and stopped:
    fading_out = true
    $fadeout.play()
    fade_out_music()
  
  if fading_out:
    circle_size -= 0.012 * Global.get_delta(delta)
    $ParallaxBackground/ParallaxLayer/Transition.visible = true
    $ParallaxBackground/ParallaxLayer/Transition.material.set_shader_param('circle_size', circle_size)
  else:
    $ParallaxBackground/ParallaxLayer/Transition.visible = false
    
  if circle_size <= -0.1:
    get_tree().change_scene(level_scenes[Global.levelID])


func _process_camera(delta: float) -> void:
  if Input.is_action_pressed('mario_right'):
    cam.global_position.x += 5 * Global.get_delta(delta)
    if Input.is_action_pressed('mario_fire'):
      cam.global_position.x += 5 * Global.get_delta(delta)

  if Input.is_action_pressed('mario_left'):
    cam.global_position.x -= 5 * Global.get_delta(delta)
    if Input.is_action_pressed('mario_fire'):
      cam.global_position.x -= 5 * Global.get_delta(delta)

  if cam.global_position.x < 320:
    cam.global_position.x = 320

  if cam.global_position.x > cam.limit_right - 320:
    cam.global_position.x = cam.limit_right - 320

func fade_out_music() -> void:
  MusicPlayer.volume_db -= 2
  yield(get_tree().create_timer( 0.05 ), 'timeout')
  if MusicPlayer.volume_db > -100 and circle_size > 0.1:
    fade_out_music()
  if MusicPlayer.volume_db < -80:
    MusicPlayer.stop()
