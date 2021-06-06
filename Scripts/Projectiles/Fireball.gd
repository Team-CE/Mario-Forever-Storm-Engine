extends KinematicBody2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(426, 0)
var skip_frame: bool = false

var belongs: int = 0 # 0 - Mario, 1 - Fire Piranha Plant, 2 - Fire Bro

func _ready() -> void:
  velocity.x *= dir
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)

func _process(delta):
  if is_on_floor():
    velocity.y = -350

  velocity.y += 24 * Global.get_delta(delta)

  velocity = move_and_slide(velocity, Vector2.UP)

func _physics_process(delta) -> void:
  var overlaps = $CollisionArea.get_overlapping_bodies()

  if overlaps.size() > 0:
    for i in range(overlaps.size()):
      if overlaps[i].is_in_group('Enemy') and overlaps[i].is_kickable:
        overlaps[i].kick()
        explode()

  if skip_frame:
    explode()

  if (is_on_wall() or velocity.x == 0) and belongs == 0:
    skip_frame = true
  
  $Sprite.rotation_degrees += 12 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)

func explode() -> void:
  var explosion = Explosion.new(position)
  get_parent().add_child(explosion)
  queue_free()

func _on_screen_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1
  queue_free()
