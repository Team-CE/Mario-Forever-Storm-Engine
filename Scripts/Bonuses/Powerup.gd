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
  if appearing and appear_counter < 35:
    position.y -= 0.7 * Global.get_delta(delta)
    appear_counter += 0.7 * Global.get_delta(delta)
    no_gravity = true
    velocity.y = 0
    $Collision.shape = null
  else:
    appearing = false
    speed = 100
    ai = AI_TYPE.WALK
    no_gravity = false
    $Collision.shape = old_col_shape
    $CollisionCollectable.shape = null
    z_index = 0

  var mario = get_parent().get_node('Mario')
  var pd_overlaps = mario.get_node('PrimaryDetector').get_overlapping_bodies()

  if pd_overlaps and pd_overlaps.has(self):
    Global.play_base_sound('MAIN_Powerup')
    var score_text = ScoreText.new(1000, position)
    get_parent().add_child(score_text)
    queue_free()
    mario.appear_counter = 50
    match type:
      POWERUP_TYPE.MUSHROOM:
        Global.state = 1

