extends Sprite
class_name BrickEffect

var y_accel: float = 0
var accel: Vector2
var local_rotation: float

func _init(pos: Vector2 = Vector2.ZERO, acceleration: Vector2 = Vector2.ZERO, textureindex: int = 0, rotat: float = Global.Mario.rotation) -> void:
  var textures = [preload('res://GFX/Bonuses/BrickDebris.png'), preload('res://GFX/Bonuses/IceBrickDebris.png'), preload('res://GFX/Bonuses/GrayBrickDebris.png')]
  texture = textures[textureindex]
  position = pos
  accel = acceleration
  z_index = 3
  rotation = rotat
  local_rotation = rotat

  if accel.x < 0:
    position += Vector2(-6, 0).rotated(rotation)
  else:
    position += Vector2(6, 0).rotated(rotation)

func _process(delta) -> void:
  y_accel += 0.4 * Global.get_delta(delta)
  position += Vector2(accel.x, accel.y + y_accel).rotated(local_rotation) * Global.get_vector_delta(delta)
  #position.x += accel.x * Global.get_delta(delta)
  #position.y += (accel.y + y_accel) * Global.get_delta(delta)

  if accel.x > 0:
    rotation_degrees += 9 * Global.get_delta(delta)
  else:
    flip_h = true
    rotation_degrees -= 9 * Global.get_delta(delta)
  
  if !Global.is_getting_closer(-32, position):
    queue_free()
