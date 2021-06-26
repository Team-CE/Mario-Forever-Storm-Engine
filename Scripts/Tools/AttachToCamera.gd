extends Sprite

func _process(_delta) -> void:
  position = Global.Mario.get_node('Camera').get_camera_screen_center() - Vector2(330, 0)
