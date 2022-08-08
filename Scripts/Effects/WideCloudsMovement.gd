extends Sprite

export var speed: float = 1
var fake_pos := Vector2.ZERO

onready var init_pos = 320

func _process(delta):
  var cam = Global.current_camera
  if !cam: return
  position.x -= speed * Global.get_delta(delta)
  fake_pos.x = init_pos + cam.get_camera_screen_center().x - 320
  if position.x >= fake_pos.x + 32:
    position.x -= 32
  if position.x < fake_pos.x - 32:
    position.x += 32
