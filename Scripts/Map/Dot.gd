extends AnimatedSprite
class_name MapDot

func _init(pos: Vector2 = Vector2.ZERO):
  frames = preload('res://Prefabs/Effects/Dot.tres')
  position = pos
  play('default')
