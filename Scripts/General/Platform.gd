extends KinematicBody2D
class_name Platform

export var horizontal_speed: float = 1
export var vertical_speed: float = 0
export var smooth_turn: bool = false
export var can_fall: bool = false
export var move_on_touch: bool = false

var velocity: Vector2

var mario_x_modifier = horizontal_speed

var dir: int = 1
var active: bool = false
var falling: bool = false

var skip_frame: bool = false

func _ready() -> void:
  if not move_on_touch:
    active = true

func _process(delta) -> void:
  if active:
    movement(delta)

func movement(delta) -> void:
  if is_on_wall() and !skip_frame:
    skip_frame = true
    horizontal_speed = -horizontal_speed
    mario_x_modifier = horizontal_speed
  if !is_on_wall():
    skip_frame = false
  
  velocity.x = horizontal_speed * 50
  velocity.y = vertical_speed * 50
  
  velocity = move_and_slide(velocity)
