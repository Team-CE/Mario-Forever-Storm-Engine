extends GenericEnemyMovement
class_name Powerup

enum POWERUP_TYPE {
  MUSHROOM,
  FLOWER,
  BEETROOT,
  LUI,
  POISON
}

export var appearing: bool = true
export(POWERUP_TYPE) var type: int = POWERUP_TYPE.MUSHROOM

var appear_counter: float = 0
var old_col_shape: RectangleShape2D

func _ready() -> void:
  old_col_shape = $Collision.shape
  z_index = -99

func _process(delta) -> void:
  if appearing and appear_counter < 44:
    position.y -= 0.7 * Global.get_delta(delta)
    appear_counter += 0.7 * Global.get_delta(delta)
    no_gravity = true
    velocity.y = 0
    $Collision.shape = null
  else:
    appearing = false
    speed = 70
    ai = AI_TYPE.WALK
    dir = 1
    no_gravity = false
    $Collision.shape = old_col_shape
    z_index = 0

