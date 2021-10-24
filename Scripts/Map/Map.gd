extends Node2D

var internal_offset: float = 0

export var music: String = ''
export var mario_speed: float = 1
export var mario_fast_speed: float = 15

var current_speed: float = mario_speed
var stopped: bool = false

func _ready() -> void:
  MusicEngine.play_music(music)

func _process(delta: float) -> void:
  $MarioPath/PathFollow2D.offset += current_speed * Global.get_delta(delta)
  $MarioPath/PathFollow2D/MiniMario/AnimatedSprite.speed_scale = 20 if !stopped else 5
  
  if Input.is_action_just_pressed('mario_jump'):
    current_speed = mario_fast_speed
    
  create_dot()
  
func create_dot() -> void:
  if internal_offset < $MarioPath/PathFollow2D.offset:
    internal_offset = $MarioPath/PathFollow2D.offset + 15
    add_child(MapDot.new($MarioPath/PathFollow2D/MiniMario.global_position))

