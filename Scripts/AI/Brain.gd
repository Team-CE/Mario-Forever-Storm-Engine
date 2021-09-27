extends Node
class_name Brain

func _setup(b) -> void:
  owner = b

# warning-ignore:unused_argument
func _ai_process(delta:float) -> void:
  if owner == null:
    return

func is_mario_collide(detector_name:String) -> bool:
  var collsions = Global.Mario.get_node(detector_name).get_overlapping_bodies()
  return collsions && collsions[0] == owner
