extends Area2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(2.4, -6)
var skip_frame: bool = false
var bounce_count: int = 0

var belongs: int = 0 # 0 - Mario, 1 - Fire Piranha Plant, 2 - Fire Bro

var rng = RandomNumberGenerator.new()

enum BLOCK_TYPE {
  COMMON,
  BRICK,
  COIN_BRICK
}

func _ready() -> void:
  velocity.x *= dir
# warning-ignore:return_value_discarded
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)
  
  rng.randomize()

func _process(delta) -> void:
  var overlaps = get_overlapping_bodies()

  if overlaps.size() > 0:
    for i in overlaps:
      if bounce_count < 2:
        if i.is_in_group('Enemy') and i.has_method('kill') and belongs == 0:
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

      if i is QBlock:
        i.hit(true, false)
  if overlaps.size() == 0:
    skip_frame = false
  
  if belongs != 0 and Global.is_mario_collide_area('InsideDetector', self):
    Global._ppd()

  velocity.y += 0.4 * Global.get_delta(delta)

  position.x += velocity.x * Global.get_delta(delta)
  position.y += velocity.y * Global.get_delta(delta)
  
  $Sprite.rotation_degrees += 38 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)

func bounce() -> void:
  velocity.y = -6
  if velocity.x > 0:
    velocity.x = rng.randi_range(-10, -3)
  elif velocity.x < 0:
    velocity.x = rng.randi_range(10, 3)
  var explosion = Explosion.new(position)
  get_parent().add_child(explosion)

func _on_screen_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1
  queue_free()

func _on_level_complete() -> float:
  var score = 100
  var score_text = ScoreText.new(score, position)
  get_parent().add_child(score_text)
  queue_free()
  return score
