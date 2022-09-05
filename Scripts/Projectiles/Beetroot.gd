extends Area2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(2.4, -6)
var skip_frame: bool = false
var bounce_count: int = 0
var drown: bool = false

var belongs: int = 0 # 0 - Mario

enum BLOCK_TYPE {
  COMMON,
  BRICK,
  COIN_BRICK
}

func _ready() -> void:
  velocity.x *= dir
# warning-ignore:return_value_discarded
  vis.connect('screen_exited', self, '_on_screen_exited')
# warning-ignore:return_value_discarded
  vis.connect('tree_exited', self, '_on_tree_exited')

  add_child(vis)

func _process(delta) -> void:
  var overlaps = get_overlapping_bodies()
  if is_over_water():
    drown = true
    velocity.y = 1.25 * Global.get_delta(delta)
    velocity.x = 0

  if overlaps.size() > 0 and bounce_count < 3 and !drown:
    for i in overlaps:
      if i.is_in_group('Enemy') and i.has_method('kill'):
        if not i.invincible:
          i.kill(AliveObject.DEATH_TYPE.FALL if !i.force_death_type else i.death_type, 0, null, self.name)
          bounce()
          bounce_count += 1
          skip_frame = true
        elif not skip_frame:
          $Bounce.play()
          bounce()
          bounce_count += 1
          skip_frame = true
      elif (i is TileMap or i.is_in_group('Solid')) and (i.visible) and not skip_frame:
        $Bounce.play()
        bounce()
        bounce_count += 1
        skip_frame = true

      if 'qtype' in i:
        i.hit()
  if overlaps.size() == 0:
    skip_frame = false

  velocity.y += 0.4 * Global.get_delta(delta)

  position.x += velocity.x * Global.get_delta(delta)
  position.y += velocity.y * Global.get_delta(delta)

func bounce() -> void:
  velocity.y = -9
  velocity.x *= -1
  var explosion = Explosion.new(position)
  get_parent().add_child(explosion)

func is_over_water() -> bool:
  var overlaps = get_overlapping_areas()
  for c in overlaps:
    if c.is_in_group('Water'):
      return true
  return false

func _on_screen_exited() -> void:
  queue_free()

func _on_tree_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1
  
func _on_level_complete() -> int:
  var score = 200
  var score_text = ScoreText.new(score, position)
  get_parent().add_child(score_text)
  queue_free()
  return score
