extends AnimatedSprite
class_name Explosion

func _init(pos: Vector2 = Vector2.ZERO):
  frames = preload('res://Prefabs/Effects/Explosion.tres')
  position = pos
  play('default')

func _process(delta) -> void:
  if frame == 3:
    queue_free()
