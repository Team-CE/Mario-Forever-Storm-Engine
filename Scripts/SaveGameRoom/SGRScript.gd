func _ready_camera(owner):
	# Reset values for save game room
	if Global.levelID != 99:
		Global.levelID = 0
	Global.checkpoint_active = -1
	Global.deaths = 0
	Global.shoe_type = 0
	Global.starman_saved = false
	Global.restartNeeded = false
	owner.shoe_node = null
