extends Area2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(2.4, -6)
var skip_frame: bool = false
var bounce_count: int = 0

var belongs: int = 0 # 0 - Mario

enum BLOCK_TYPE {
  COMMON,
  BRICK,
  COIN_BRICK
}

func _ready() -> void:
  velocity.x *= dir
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)

func _physics_process(delta) -> void:
  var overlaps = get_overlapping_bodies()

  if overlaps.size() > 0 and bounce_count < 3:
    for i in range(overlaps.size()):
      if overlaps[i].is_in_group('Enemy') and overlaps[i].is_kickable:
        overlaps[i].kick(0)
        bounce()
        bounce_count += 1
        skip_frame = true
      elif (overlaps[i] is TileMap or overlaps[i].is_in_group('Solid')) and (overlaps[i].visible) and not skip_frame:
        $Bounce.play()
        bounce()
        bounce_count += 1
        skip_frame = true

      if 'qtype' in overlaps[i]:
        overlaps[i].hit(delta)
  if overlaps.size() == 0:
    skip_frame = false

  velocity.y += 0.4 * Global.get_delta(delta)

  position.x += velocity.x * Global.get_delta(delta)
  position.y += velocity.y * Global.get_delta(delta)

func bounce() -> void:
  var explosion = Explosion.new(position)
  get_parent().add_child(explosion)
  velocity.y = -9
  velocity.x *= -1

func _on_screen_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1
  queue_free()
