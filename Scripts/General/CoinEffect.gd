extends AnimatedSprite
class_name CoinEffect

var counter: float = 10
var first_pos: Vector2

func _init(pos: Vector2 = Vector2.ZERO):
  frames = preload('res://Prefabs/Bonuses/CoinEffect.tres')
  first_pos = pos
  position = pos

func _process(delta) -> void:
  play('default')
  if counter > 0:
    counter -= 0.5 * Global.get_delta(delta)
  elif counter < 0:
    counter = 0
  
  position.y -= counter * Global.get_delta(delta)

  if frame == 21:
    var score_text = ScoreText.new(200, first_pos)
    get_parent().add_child(score_text)
    queue_free()
