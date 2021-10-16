extends Node
class_name Brain

var colliding: bool = false

func _setup(b) -> void:
  owner = b

# warning-ignore:unused_argument
func _ai_process(delta:float) -> void:
  if owner == null:
    return

func is_mario_collide(_detector_name: String) -> bool:
  var collisions = Global.Mario.get_node(_detector_name).get_overlapping_bodies()
  return collisions && collisions[0] == owner

func on_mario_collide(_detector_name: String) -> bool:
  if !colliding && is_mario_collide(_detector_name):
    colliding = true
    return true
  elif colliding && !is_mario_collide(_detector_name):
    colliding = false
  return false
