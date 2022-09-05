extends Area2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(350, -650)
var skip_frame: bool = false
var gravity_scale: float = 1

var trail_counter: float = 0

var belongs: int = 0 # 0 - Mario, 1 - Bro, 2 - Spikeball Launcher

func _ready() -> void:
  velocity.x *= dir
# warning-ignore:return_value_discarded
  vis.connect('screen_exited', self, '_on_screen_exited')
# warning-ignore:return_value_discarded
  vis.connect('tree_exited', self, '_on_tree_exited')

  add_child(vis)

func _process(delta) -> void:
  var overlaps = self.get_overlapping_bodies()

  if overlaps.size() > 0 and belongs == 0:
    for i in overlaps:
      if i.is_in_group('Enemy') and i.has_method('kill'):
        i.kill(AliveObject.DEATH_TYPE.FALL if !i.force_death_type else i.death_type, 0, null, self.name)
        
  if belongs != 0 and is_mario_collide('InsideDetector'):
    Global._ppd()

  if belongs == 2 and position.y > 512:
    queue_free()

  velocity.y += (12 if belongs == 1 else 5) * gravity_scale * Global.get_delta(delta)

  position += velocity / 50.0 * Global.get_delta(delta)
  
  $Sprite.rotation_degrees += 20 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)
  $Sprite.flip_h = velocity.x < 0
  
  trail_counter -= 1 * Global.get_delta(delta)
  
  if trail_counter <= 0:
    trail_counter = 2
    get_parent().add_child(SawTrail.new(position, rotation_degrees))
  
func is_mario_collide(_detector_name: String) -> bool:
  var collisions = Global.Mario.get_node(_detector_name).get_overlapping_areas()
  return collisions && collisions.has(self)

func explode() -> void:
  var explosion = Explosion.new(position)
  get_parent().add_child(explosion)
  queue_free()

func _on_screen_exited() -> void:
  if belongs == 2:
    return
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
