extends Sprite


var posY = position.y
var timer: float = 0

func _ready():
  pass # Replace with function body.


func _process(delta):
  position.y = posY + sin(timer) * 10
  timer += 0.2 * Global.get_delta(delta)
