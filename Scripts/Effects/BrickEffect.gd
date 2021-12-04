extends Sprite
class_name BrickEffect

var y_accel: float = 0
var accel: Vector2

func _init(pos: Vector2 = Vector2.ZERO, acceleration: Vector2 = Vector2.ZERO, text: int = 0) -> void:
  var textures = [preload('res://GFX/Bonuses/BrickDebris.png'), preload('res://GFX/Bonuses/IceBrickDebris.png')]
  texture = textures[text]
  position = pos
  accel = acceleration
  z_index = 3

  if accel.x < 0:
    position.x -= 6
  else:
    position.x += 6

func _process(delta) -> void:
  y_accel += 0.4 * Global.get_delta(delta)
  position.x += accel.x * Global.get_delta(delta)
  position.y += (accel.y + y_accel) * Global.get_delta(delta)

  if accel.x > 0:
    rotation_degrees += 9 * Global.get_delta(delta)
  else:
    flip_h = true
    rotation_degrees -= 9 * Global.get_delta(delta)
  
  if position.y > Global.Mario.position.y + 480:
    queue_free()
