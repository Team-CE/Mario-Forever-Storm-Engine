extends Area2D

var rng = RandomNumberGenerator.new()
var type = 0
var velocity: Vector2

func _ready() -> void:
  if type == 1:
    velocity.y = rand_range(-2, -7.5)
    z_index = -49
  elif type == 0 and !is_in_water():
    queue_free()
  
func _process(delta) -> void:
  if $AnimatedSprite.animation == 'disappear':
    if $AnimatedSprite.frame > 6:
      queue_free()
    return
  
  if type == 0:
    position.y -= rng.randf_range(0, 3) * Global.get_delta(delta)
    position.x += rng.randf_range(-2, 2) * Global.get_delta(delta)
  
  if type == 1:
    if !Global.is_getting_closer(-32, position):
      queue_free()
    position += velocity * Global.get_delta(delta)

func is_in_water() -> bool:
  for c in get_overlapping_areas():
    if c.is_in_group('Water'):
      return true
  return false

func _on_area_exited(area) -> void:
  if area.is_in_group('Water') and type == 0:
    $AnimatedSprite.play('disappear')
