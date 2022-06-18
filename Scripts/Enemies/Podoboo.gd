extends Area2D

var velocity := Vector2.ZERO
onready var firstpos = position

func _process(delta):
  position += velocity # start y = -12.8
  velocity.y += 0.2 * Global.get_delta(delta)
  pass
