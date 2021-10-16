extends GenericEnemyMovement
class_name Powerup, "res://GFX/Editor/Powerup.png"

enum POWERUP_TYPE {
  MUSHROOM,
  FLOWER,
  BEETROOT,
  LUI,
  POISON,
  LIFE
}

export(POWERUP_TYPE) var type: int = POWERUP_TYPE.MUSHROOM

func _ready() -> void:
  z_index = -99

  if Global.state == 0 and appearing:
    speed = 100
    type = POWERUP_TYPE.MUSHROOM
    gravity_modifier = 1
    ai = AI_TYPE.WALK
    jump_height = 0
    $Sprite.set_animation('Mushroom')

  if type == POWERUP_TYPE.FLOWER:
    old_speed = 0
    $Sprite.set_animation('Flower')

  if type == POWERUP_TYPE.BEETROOT:
    old_speed = 0
    $Sprite.set_animation('Beetroot')
    
  if type == POWERUP_TYPE.LUI:
    old_speed = 0
    $Sprite.set_animation('Green Lui')

func _process(delta) -> void:
  if appearing and appear_counter < 32:
    if type != POWERUP_TYPE.MUSHROOM and type != POWERUP_TYPE.POISON and type != POWERUP_TYPE.LIFE:
      $CollisionCollectable.disabled = true
  else:
    $CollisionCollectable.disabled = true

  if type != POWERUP_TYPE.MUSHROOM and type != POWERUP_TYPE.POISON and type != POWERUP_TYPE.LIFE:
    $Sprite.flip_h = false

  var mario = get_parent().get_node('Mario')
  var pd_overlaps = mario.get_node('BottomDetector').get_overlapping_bodies()

  if pd_overlaps and pd_overlaps.has(self):
    queue_free()
    match type:
      POWERUP_TYPE.MUSHROOM:
        if Global.state == 0:
          Global.state = 1
          mario.appear_counter = 60
          Global.add_score(1000)
        else:
          var score_text = ScoreText.new(1000, position)
          get_parent().add_child(score_text)
        Global.play_base_sound('MAIN_Powerup')
      POWERUP_TYPE.FLOWER:
        if Global.state != 2:
          mario.appear_counter = 60
          Global.add_score(1000)
        if Global.state >= 1:
          Global.state = 2
          var score_text = ScoreText.new(1000, position)
          get_parent().add_child(score_text)
        else:
          Global.state = 1
          Global.add_score(1000)
      POWERUP_TYPE.BEETROOT:
        if Global.state != 3:
          mario.appear_counter = 60
          Global.add_score(1000)
        if Global.state >= 1:
          Global.state = 3
          var score_text = ScoreText.new(1000, position)
          get_parent().add_child(score_text)
        else:
          Global.state = 1
          Global.add_score(1000)
      POWERUP_TYPE.LUI:
        if Global.state != 4:
          mario.appear_counter = 60
          Global.add_score(1000)
        if Global.state >= 1:
          Global.state = 4
          var score_text = ScoreText.new(1000, position)
          get_parent().add_child(score_text)
        else:
          Global.state = 1
          Global.add_score(1000)
      POWERUP_TYPE.LIFE:
        Global.add_lives(1, true)
      POWERUP_TYPE.POISON:
        Global._pll()
        var explosion = Explosion.new(position + Vector2(0, -16))
        get_parent().add_child(explosion)
