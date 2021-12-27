extends AnimatedSprite

var counter: float = 0
var proc: bool = false

func _ready():
  visible = false

func _process(_delta: float) -> void:
  if !proc:
    visible = position.x <= get_parent().get_parent().get_node('MarioPath/PathFollow2D/MiniMario').global_position.x
    proc = true

  var mario = get_parent().get_parent().get_node('MarioPath/PathFollow2D/MiniMario')
  if (
    mario.global_position.x > position.x - 12 and
    mario.global_position.x < position.x + 12 and
    mario.global_position.y > position.y - 12 and
    mario.global_position.y < position.y + 12
  ) and counter <= 12:
    counter += get_parent().get_parent().current_speed * Global.get_delta(_delta)
    
    if counter > 12:
      visible = true
