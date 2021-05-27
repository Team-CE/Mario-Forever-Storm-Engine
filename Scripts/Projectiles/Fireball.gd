extends KinematicBody2D

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(426, 0)

var belongs: int = 0 # 0 - Mario, 1 - Fire Piranha Plant, 2 - Fire Bro

func _ready() -> void:
  velocity.x *= dir
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)

func _process(delta) -> void:
  if is_on_floor():
    velocity.y = -350

  velocity.y += 24 * Global.get_delta(delta)

  velocity = move_and_slide(velocity, Vector2.UP)

  if is_on_wall() and belongs == 0:
    var explosion = Explosion.new(position)
    get_parent().add_child(explosion)
    queue_free()
  
  $Sprite.rotation_degrees += 12 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)

func _on_screen_exited() -> void:
  if belongs == 0:
    Global.projectiles_count -= 1
  queue_free()
