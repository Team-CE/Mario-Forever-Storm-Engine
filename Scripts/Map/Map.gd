extends Node2D

var internal_offset: float = 0

export var music: Resource
export var mario_speed: float = 1
export var mario_fast_speed: float = 15
export var stop_points: Array = []
export var level_scenes: Array = []
export var camera_left_limit: int = 0
export var camera_right_limit: int = 10000
export var camera_top_limit: int = 0
export var camera_bottom_limit: int = 480

var current_speed: float = mario_speed
var stopped: bool = false

var fading_out: bool = false
var circle_size: float = 0.623

onready var cam = $MarioPath/PathFollow2D/MiniMario/Camera2D

func _ready() -> void:
  MusicPlayer.get_node('Main').stream = music
  MusicPlayer.get_node('Main').play()
  MusicPlayer.play_on_pause()
  
  if Global.levelID > 0:
    $MarioPath/PathFollow2D.offset = stop_points[Global.levelID - 1]
  
  $MarioPath/PathFollow2D/MiniMario/Camera2D.limit_left = camera_left_limit
  $MarioPath/PathFollow2D/MiniMario/Camera2D.limit_right = camera_right_limit
  $MarioPath/PathFollow2D/MiniMario/Camera2D.limit_top = camera_top_limit
  $MarioPath/PathFollow2D/MiniMario/Camera2D.limit_bottom = camera_bottom_limit
  
  Global.call_deferred('reset_audio_effects')
  Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

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
    var fadeout = $fadeout.duplicate()
    get_node('/root').add_child(fadeout)
    fadeout.play()
    MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 2.0)
  
  if fading_out:
    circle_size -= 0.012 * Global.get_delta(delta)
    $ParallaxBackground/ParallaxLayer/Transition.visible = true
    $ParallaxBackground/ParallaxLayer/Transition.material.set_shader_param('circle_size', circle_size)
  else:
    $ParallaxBackground/ParallaxLayer/Transition.visible = false
    
  if circle_size <= -0.1:
    Global.goto_scene(level_scenes[Global.levelID])


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
