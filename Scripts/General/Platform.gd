extends PathFollow2D
class_name Platform

export var speed: float = 1
export var vertical_speed: float = 0
export var smooth_turn: bool = false
export var smooth_turn_distance: float = 100
export var can_fall: bool = false
export var move_on_touch: bool = false

var current_speed: float = 0

var velocity: Vector2

var dir: int = 1
var active: bool = false
var falling: bool = false
var y_speed: float = 0

var skip_frame: bool = false

func _ready() -> void:
  if not move_on_touch:
    active = true
    current_speed = speed

func _process(delta) -> void:
  if active:
    movement(delta)

func movement(delta) -> void:
  offset += current_speed * Global.get_delta(delta)
  
  if smooth_turn:
    var points = get_parent().curve.get_baked_points()
    for i in range(len(points)):
      var p_offset = get_parent().curve.get_closest_offset(points[i])
      if p_offset < smooth_turn_distance and p_offset != 0:
        current_speed = speed * (p_offset / smooth_turn_distance) + 0.2
        
  if falling:
    y_speed += 0.2 * Global.get_delta(delta)
    position += Vector2(0, y_speed).rotated(rotation) * Global.get_delta(delta)

func _standing_on():
  if can_fall:
    falling = true
