func _ready_camera(owner):
  # Reset values for save game room
  Global.levelID = 0
  Global.checkpoint_active = -1
  Global.deaths = 0
  Global.shoe_type = 0
  owner.shoe_node = null
