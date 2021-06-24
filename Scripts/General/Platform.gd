extends Area2D
class_name Platform

export var horizontal_speed: float = 1
export var vertical_speed: float = 0
export var smooth_turn: bool = false
export var can_fall: bool = false
export var move_on_touch: bool = false

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
  if get_overlapping_bodies().size() and get_overlapping_bodies()[0] is TileMap and not skip_frame:
    skip_frame = true
    horizontal_speed = -horizontal_speed
  if get_overlapping_bodies().size() == 0:
    skip_frame = false
  
  position.x += horizontal_speed * Global.get_delta(delta)
  position.y += vertical_speed * Global.get_delta(delta)
