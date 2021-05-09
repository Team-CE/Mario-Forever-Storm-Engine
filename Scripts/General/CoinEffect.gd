extends AnimatedSprite
class_name CoinEffect

var counter = 10

func _init(pos: Vector2 = Vector2.ZERO):
  position = pos

func _process(delta) -> void:
  play()
  if counter > 0:
    counter -= 0.5 * Global.get_delta(delta)
  elif counter < 0:
    counter = 0
  
  position.y -= counter * Global.get_delta(delta)
  
