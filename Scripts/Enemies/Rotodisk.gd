tool
extends Node2D


var counter: float = 0
var dir: bool = false

export var radius: float = 150 setget reset_offset
export var speed: float = 2
export var flower_movement: bool = false setget reset_flower
export var angle: float = 0
export var flower_speed: float = 5

func _ready() -> void:
  if not flower_movement:
    $Sprite/Node2D/AnimatedSprite.position.y = 0 - radius
  $Sprite/Node2D.rotation_degrees += angle

func _process(delta) -> void:
  if flower_movement:
    counter += flower_speed * get_delta(delta)
    if counter >= 200:
      counter = 0
      if dir == true: $Sprite/Node2D/AnimatedSprite.position.y = 0
      dir = true if dir == false else false
    
    $Sprite/Node2D/AnimatedSprite.position.y += (flower_speed if dir else 0 - flower_speed) * get_delta(delta)
  
  $Sprite/Node2D.rotation += (speed / 100) * get_delta(delta)
  $Sprite/Node2D/AnimatedSprite.global_rotation = 0
  
  if Engine.editor_hint: return
  
  if Global.is_mario_collide_area('InsideDetector', $Sprite/Node2D/AnimatedSprite/Area2D):
    Global._ppd()

func reset_offset(new_offset):
  if not flower_movement:
    radius = new_offset
    $Sprite/Node2D/AnimatedSprite.position.y = 0 - radius
  else:
    printerr('[CE Error]: Please turn off flower movement before changing the radius.')

func reset_flower(new_bool):
  flower_movement = new_bool
  $Sprite/Node2D.rotation_degrees = angle
  counter = 0
  dir = false
  $Sprite/Node2D.rotation = 0
  $Sprite/Node2D/AnimatedSprite.position.y = 0 if flower_movement else 0 - radius
  return

static func get_delta(delta) -> float:       # Delta by 50 FPS
  return 50 / (1 / (delta if not delta == 0 else 0.0001))
