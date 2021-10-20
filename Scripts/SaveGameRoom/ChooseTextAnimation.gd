extends Sprite

var initial_y: float
var counter: float = 0

func _ready() -> void:
  initial_y = position.y

func _process(delta: float) -> void:
  counter += 0.05 * Global.get_delta(delta)
  position.y = initial_y + (sin(counter) * 10)
