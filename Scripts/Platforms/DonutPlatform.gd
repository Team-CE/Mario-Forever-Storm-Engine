extends KinematicBody2D

export var delay: int = 2
var falling: bool = false
var counter: float = 0
var standoff_counter: float = 0
var counting: bool = false
var y_speed: float = 0
var initial_position: Vector2

func _ready() -> void:
  initial_position = position

func _process(delta: float) -> void:
  if counting:
    counter += 1 * Global.get_delta(delta)
    
  if standoff_counter > 0 and y_speed == 0:
    standoff_counter -= 3 * Global.get_delta(delta)
  elif y_speed == 0:
    counting = false
    counter = 0
    
  if standoff_counter <= 0:
    position = initial_position
  
  if counter > delay * 50:
    y_speed += 0.2 * Global.get_delta(delta)
    position += Vector2(0, y_speed).rotated(rotation) * Global.get_delta(delta)
  elif counting:
    position = initial_position + Vector2(cos(counter), 0).rotated(rotation)
  
func _standing_on():
  counting = true
  standoff_counter = 3
