class_name MFPickUp extends MFEntity

signal player_collect()


func picked_up() -> void:
	# Place Holder
	# Can be added more logic and can fail to pick up
	emit_signal('player_collect')
