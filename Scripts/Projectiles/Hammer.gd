extends KinematicBody2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(350, -650)
var skip_frame: bool = false
var gravity_scale: float = 1

var belongs: int = 0 # 0 - Mario, 1 - Bro

func _ready() -> void:
  velocity.x *= dir
# warning-ignore:return_value_discarded
  vis.connect('screen_exited', self, '_on_screen_exited')
  vis.connect('tree_exited', self, '_on_tree_exited')

  add_child(vis)

func _process(delta) -> void:
  var overlaps = $CollisionArea.get_overlapping_bodies()

  if overlaps.size() > 0 and belongs == 0:
    for i in overlaps:
      if i.is_in_group('Enemy') and i.has_method('kill'):
        i.kill(AliveObject.DEATH_TYPE.FALL, 0, null, self.name)
        explode()
        
  if belongs != 0 and is_mario_collide('InsideDetector'):
    Global._ppd()

  velocity.y += 16 * gravity_scale * Global.get_delta(delta)

  move_and_slide(velocity, Vector2.UP)
  
  $Sprite.rotation_degrees += 6 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)
  $Sprite.flip_h = velocity.x < 0
  
func is_mario_collide(_detector_name: String) -> bool:
  var collisions = Global.Mario.get_node(_detector_name).get_overlapping_areas()
  return collisions && collisions.has($CollisionArea)

func explode() -> void:
  var explosion = Explosion.new(position)
  get_parent().add_child(explosion)
  queue_free()

func _on_screen_exited() -> void:
  queue_free()

func _on_tree_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1

func _on_level_complete() -> float:
  var score = 100
  var score_text = ScoreText.new(score, position)
  get_parent().add_child(score_text)
  queue_free()
  return score
