extends KinematicBody2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(426, 0)
var skip_frame: bool = false
var gravity_scale: float = 1

var counter: int = 0

var belongs: int = 0 # 0 - Mario, 1 - Piranha Plant, 2 - Bro

func _ready() -> void:
  velocity.x *= dir
  if Global.quality == 0 and get_node_or_null('Light2D'):
    $Light2D.queue_free()
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)
  
  var children = get_parent().get_children()
  for node in range(len(children)):
    if 'AI' in children[node]:
      add_collision_exception_with(children[node])

func _process(delta) -> void:
  var overlaps = $CollisionArea.get_overlapping_bodies()

  if overlaps.size() > 0 and belongs == 0:
    for i in range(overlaps.size()):
      if overlaps[i].is_in_group('Enemy') and overlaps[i].has_method('freeze'):
        overlaps[i].freeze()
        explode()
        
  if belongs != 0 and is_mario_collide('InsideDetector'):
    Global._ppd()

  if is_on_floor() and belongs != 1:
    counter += 1
    velocity.y = -350
    if counter > 2:
      explode()

  velocity.y += 24 * gravity_scale * Global.get_delta(delta)

  if belongs != 1:
    velocity = move_and_slide(velocity, Vector2.UP)
  else:
    position += velocity * Vector2(delta, delta)

  if (is_on_wall() or velocity.x == 0) and belongs != 1:
    explode()
  
  $Sprite.rotation_degrees += 12 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)
  
func is_mario_collide(_detector_name: String) -> bool:
  var collisions = Global.Mario.get_node(_detector_name).get_overlapping_bodies()
  return collisions && collisions.has(self)

func explode() -> void:
  var explosion = IceExplosion.new(position)
  get_parent().add_child(explosion)
  queue_free()

func _on_screen_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1
  queue_free()
