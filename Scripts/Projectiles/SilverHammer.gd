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
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)
  
  rng.randomize()

func _process(delta) -> void:
  var overlaps = get_overlapping_bodies()

  if overlaps.size() > 0 and bounce_count < 3:
    for i in range(overlaps.size()):
      if overlaps[i].is_in_group('Enemy') and overlaps[i].has_method('kill') and belongs == 0:
        if not overlaps[i].invincible:
          overlaps[i].kill(AliveObject.DEATH_TYPE.FALL, 0, null, self.name)
          bounce()
          bounce_count += 1
          skip_frame = true
        elif not skip_frame:
          $Bounce.play()
          bounce()
          bounce_count += 1
          skip_frame = true
      elif (overlaps[i] is TileMap or overlaps[i].is_in_group('Solid')) and (overlaps[i].visible) and not skip_frame:
        $Bounce.play()
        bounce()
        bounce_count += 1
        skip_frame = true

      if overlaps[i] is QBlock:
        overlaps[i].hit(delta, true)
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
