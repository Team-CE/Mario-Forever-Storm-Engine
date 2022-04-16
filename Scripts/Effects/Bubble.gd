extends Area2D
class_name BubbleEffect

var rng = RandomNumberGenerator.new()
var type = 0

func _init(pos: Vector2 = Vector2.ZERO, typer: int = 0) -> void:
  position = pos
  type = typer
  if !is_in_water(self):
    queue_free()
  
func _process(delta):
  if type == 0:
    position.y -= rng.randf_range(0, 3) * Global.get_delta(delta)
    position.x += rng.randf_range(-2, 2) * Global.get_delta(delta)
  
func is_in_water(obj) -> bool:
  var overlaps = obj.get_overlapping_bodies()

  if overlaps.size() > 0 && (overlaps[0].is_in_group('Water')) and (overlaps[0].visible):
    return true

  return false

