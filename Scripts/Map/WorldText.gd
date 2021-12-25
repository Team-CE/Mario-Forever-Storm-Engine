extends Sprite

var y_speed: float = 0

func _process(delta: float) -> void:
  y_speed += 0.4 * Global.get_delta(delta)
  
  if position.y > -190:
    y_speed = -3
    
  position.y += y_speed * Global.get_delta(delta)
