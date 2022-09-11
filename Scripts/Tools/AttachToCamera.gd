extends Sprite

func _process(_delta) -> void:
	var camera = Global.current_camera
	if !camera: return
	position = camera.get_camera_screen_center() - Vector2(330, 0)
