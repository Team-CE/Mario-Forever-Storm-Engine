extends AnimatedSprite

var counter: float = 0
var proc: bool = false
var collided: bool = false
onready var mario = Global.Mario

func _ready():
  visible = false
  playing = true

func _process(delta: float) -> void:
  if !proc:
    visible = position.x <= mario.global_position.x
    proc = true

  if (
    mario.global_position.x > position.x - 12 and
    mario.global_position.x < position.x + 12 and
    mario.global_position.y > position.y - 12 and
    mario.global_position.y < position.y + 12
  ) and counter <= 20:
    collided = true
  
  if collided:
    counter += get_parent().get_parent().current_speed * Global.get_delta(delta)
    
    if counter > 20:
      visible = true
