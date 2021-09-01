extends AIBase

static func _ai_process(delta:float,b:AliveObject) -> void:
  b.velocity.x = b.speed * b.dir
  if !b.is_on_floor():
    b.velocity.y += Global.gravity * b.gravity_scale
  if b.is_on_wall():
    b.turn()
  
