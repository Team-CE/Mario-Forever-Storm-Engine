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

onready var cam = $MarioPath/PathFollow2D/MiniMario/Camera

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
    
  if stopped:
    _process_camera(delta)

  if Input.is_action_just_pressed('mario_jump') and !fading_out and stopped:
    fading_out = true
    $fadeout.play()
    MusicPlayer.stop()
  
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
    cam.position.x += 5 * Global.get_delta(delta)
    if Input.is_action_pressed('mario_fire'):
      cam.position.x += 3 * Global.get_delta(delta)

  if Input.is_action_pressed('mario_left'):
    cam.position.x -= 5 * Global.get_delta(delta)
    if Input.is_action_pressed('mario_fire'):
      cam.position.x -= 3 * Global.get_delta(delta)

  if cam.get_camera_position().x < 320:
    cam.position.x = 320
    
  if cam.get_camera_position().x > cam.limit_right - 320:
    cam.position.x = cam.limit_right - 320
