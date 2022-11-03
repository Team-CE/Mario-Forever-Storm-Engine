extends Sprite

export var speed: float = 1
var fake_pos := Vector2.ZERO

export var init_pos = 320

func _physics_process(delta):
	var cam = Global.current_camera
	if !cam: return
	position.x -= speed * Global.get_delta(delta)
	fake_pos.x = init_pos + cam.get_camera_screen_center().x - 320
	while position.x >= fake_pos.x + 32:
		position.x -= 32
	while position.x < fake_pos.x - 32:
		position.x += 32
