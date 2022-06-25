extends AnimatedSprite
class_name Explosion

func _init(pos: Vector2 = Vector2.ZERO):
  frames = preload('res://Prefabs/Effects/Explosion.tres')
  position = pos
  modulate.r = 1.2
  modulate.g = 1.2
  modulate.b = 1.2
  z_index = 1
  play('default')

func _process(_delta) -> void:
  if frame == 3:
    queue_free()
