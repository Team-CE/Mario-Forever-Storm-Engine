extends PathFollow2D
class_name Platform

export var speed: float = 1
export var vertical_speed: float = 0
export var smooth_turn: bool = false
export var smooth_turn_distance: float = 48
export var smooth_point: float
export var can_fall: bool = false
export var move_on_touch: bool = false

var current_speed: float = 0
var max_offset: float
var tween: SceneTreeTween
var tween_state: int

var velocity: Vector2

var dir: int = 1
var active: bool = false

var falling: bool = false
var y_speed: float = 0
var fall_position: Vector2
var fall_bool: bool = false

func _ready() -> void:
  process_priority = -100
  if not move_on_touch:
    active = true
    current_speed = speed
  if smooth_turn:
    var old_offset = offset
    unit_offset = 1.0
    max_offset = offset
    offset = old_offset
    
    if !smooth_point:
      smooth_point = max_offset / 2
    

func _physics_process(delta) -> void:
  if active:
    movement(delta)

func movement(delta) -> void:
  if !is_nan(current_speed) and !smooth_turn:
    offset += current_speed * Global.get_delta(delta)
  
  if smooth_turn:
    smooth_turn_movement(delta)
  
  if vertical_speed != 0:
    v_offset += vertical_speed * Global.get_delta(delta)
    if (position.y > 512 and vertical_speed > 0) or (position.y < -32 and vertical_speed < 0):
      v_offset = 0
# warning-ignore:return_value_discarded
  
  if falling:
    y_speed += 0.2 * Global.get_delta(delta)
    if !fall_bool:
      fall_bool = true
      fall_position = position
    fall_position += Vector2(0, y_speed).rotated(rotation) * Global.get_delta(delta)
    position.y = fall_position.y

func smooth_turn_movement(delta) -> void:
  if !tween:
    tween = new_tw()
    tween.tween_property(self, 'offset', offset + smooth_turn_distance, 1.8 / speed).set_ease(Tween.EASE_IN)
    if offset > smooth_point - smooth_turn_distance:
      tween_state = 2
  
  if tween_state == 1:
    offset += current_speed * Global.get_delta(delta)
    if offset > smooth_point - smooth_turn_distance:
      tween = new_tw()
# warning-ignore:return_value_discarded
      tween.tween_property(self, 'offset', smooth_point, 1.8 / speed).set_ease(Tween.EASE_OUT)
# warning-ignore:return_value_discarded
      tween.tween_property(self, 'offset', smooth_point + smooth_turn_distance, 1.8 / speed).set_ease(Tween.EASE_IN)
      tween_state += 1
  elif tween_state == 3:
    offset += current_speed * Global.get_delta(delta)
    if offset > max_offset - smooth_turn_distance:
      tween = new_tw()
# warning-ignore:return_value_discarded
      tween.tween_property(self, 'offset', max_offset, 1.8 / speed).set_ease(Tween.EASE_OUT)
# warning-ignore:return_value_discarded
      tween.tween_property(self, 'offset', max_offset + smooth_turn_distance, 1.8 / speed).set_ease(Tween.EASE_IN)
      tween_state += 1

func new_tw() -> SceneTreeTween:
  var tw = create_tween()
  tw.connect('finished', self, '_on_tween_finish')
  tw.set_trans(Tween.TRANS_SINE)
  tw.set_process_mode(0)
  return tw

func _on_tween_finish() -> void:
  tween_state += 1
  if tween_state == 5:
    tween_state = 1
