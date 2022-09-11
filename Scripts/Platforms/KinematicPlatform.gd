extends KinematicBody2D

func _standing_on():
	if 'can_fall' in get_parent() and get_parent().can_fall:
		get_parent().falling = true
	if 'move_on_touch' in get_parent() and get_parent().move_on_touch:
		get_parent().active = true
		get_parent().current_speed = get_parent().speed
		get_parent().move_on_touch = false
