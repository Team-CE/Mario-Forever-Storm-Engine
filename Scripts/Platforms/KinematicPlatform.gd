extends KinematicBody2D

func _standing_on():
  if get_parent().can_fall:
    get_parent().falling = true
