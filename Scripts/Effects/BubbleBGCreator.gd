extends Node2D

export var bubble = preload('res://Objects/Effects/BubbleEffect.tscn')

var timer: float

func _ready():
  pass

func _process(delta):
  if !Global.is_getting_closer(-32, position):
    return
  if timer < 5:
    timer += Global.get_delta(delta)
  else:
    timer = 0
    if round(rand_range(1, 11)) == 10:
      var bub = bubble.instance()
      bub.type = 1
      get_parent().add_child(bub)
      bub.global_position = global_position + Vector2(0, round(rand_range(-10, 10)))
