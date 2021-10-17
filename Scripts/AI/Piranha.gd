extends Brain

var piranha_counter: float = 0
var initial_pos: Vector2
var offset_pos: Vector2 = Vector2.ZERO

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.DISAPPEAR
  owner.velocity_enabled = false
  initial_pos = owner.position
  owner.get_node('Placeholder1').queue_free()
  owner.get_node('Placeholder2').queue_free()
  owner.get_node('Placeholder3').queue_free()
  
func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !owner.alive:
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    owner.velocity_enabled = true
    return

  if on_mario_collide('InsideDetector'):
    Global._ppd()

  piranha_counter += 1 * Global.get_delta(delta)
  
  if piranha_counter == 0:
    offset_pos = Vector2.ZERO

  if piranha_counter < 64:
    offset_pos += Vector2(0, -1).rotated(owner.rotation) * Global.get_delta(delta)
  
  if piranha_counter >= 130 and piranha_counter < 194:
    offset_pos += Vector2(0, 1).rotated(owner.rotation) * Global.get_delta(delta)
  
  if piranha_counter >= 260 and (Global.Mario.position.x < owner.position.x - 80 or Global.Mario.position.x > owner.position.x + 80):
    piranha_counter = 0
    
  owner.position = initial_pos + offset_pos

