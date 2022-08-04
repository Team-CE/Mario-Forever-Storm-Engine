extends Sprite

func _init(pos: Vector2 = Vector2.ZERO, r: float = 0):
  texture = preload('res://GFX/Miscellaneous/CheckpointEffect.png')
  position = pos
  modulate.a = 0.55
  rotation = r

func _process(delta) -> void:
  modulate.a -= 0.05 * Global.get_delta(delta)
  if modulate.a <= 0.01:
    queue_free()
