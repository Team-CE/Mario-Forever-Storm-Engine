extends Area2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int
var speed: float = 3.16
var falling: bool = false

var y_accel: float = 0

func _process(delta) -> void:
  position.x += speed * dir * Global.get_delta(delta)
  $Sprite.flip_h = dir == -1

  if not falling:
    var mario_bd = Global.Mario.get_node('BottomDetector')
    var mario_pd = Global.Mario.get_node('InsideDetector')
    var pd_overlaps = mario_pd.get_overlapping_areas()
    var bd_overlaps = mario_bd.get_overlapping_areas()

    if (bd_overlaps and bd_overlaps.has(self)) and not (pd_overlaps and pd_overlaps.has(self)):
      Global.enemy_bounce()
      var score_text = ScoreText.new(100, position)
      get_parent().add_child(score_text)
      falling = true
      Global.play_base_sound('ENEMY_Stomp')
      
    if pd_overlaps and pd_overlaps[0] == self:
      Global._ppd()
  else:
    position.y += y_accel * Global.get_delta(delta)
    y_accel += 0.2 * Global.get_delta(delta)
