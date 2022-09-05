extends Sprite

const trail = preload('res://Scripts/Effects/CheckpointTrail.gd')

var trail_counter: float
var velocity := Vector2(0, -10)
var counter: float
var has_rotated: bool = false

func _ready():
  pass

func _process(delta):
  if !visible: return
  
  position += velocity * Global.get_vector_delta(delta)
  if velocity.y < 0:
    velocity.y += 0.4 * Global.get_delta(delta)
    
    trail_counter += 1 * Global.get_delta(delta)
    if trail_counter > 1:
      get_parent().add_child(trail.new(position))
      trail_counter = 0
  else:
    velocity.y = 0
    if counter < 50:
      counter += 1 * Global.get_delta(delta)
    else:
      get_parent().add_child(trail.new(position, true))
      queue_free()
    
  if !has_rotated:
    rotation_degrees -= 20 * Global.get_delta(delta)
    if rotation_degrees <= -360:
      rotation_degrees = 0
      has_rotated = true
  
