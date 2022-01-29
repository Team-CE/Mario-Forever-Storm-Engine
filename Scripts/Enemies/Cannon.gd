extends StaticBody2D
class_name Cannon, "res://GFX/Editor/Enemy.png"

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var on_screen: bool
var counter: float = 0

export var result: PackedScene = preload('res://Objects/Enemies/Bullet.tscn')

func _ready() -> void:
  vis.process_parent = true
  vis.physics_process_parent = true
  vis.connect('screen_entered', self, '_on_screen_entered')
  vis.connect('screen_exited', self, '_on_screen_exited')

  add_child(vis)

func _process(delta) -> void:
  if on_screen and (position.x > Global.Mario.position.x + 80 or position.x < Global.Mario.position.x - 80):
    counter += 1 * Global.get_delta(delta)
  
  if counter > 25:
    $Shoot.play()
    counter = rand_range(50, 200) * -1
    var bullet = result.instance()
    bullet.position = Vector2(position.x, position.y)
    bullet.dir = -1 if Global.Mario.position.rotated(-rotation).x < position.rotated(-rotation).x else 1
    bullet.rotation = rotation
    var explosionPos = position + Vector2(bullet.dir * 16, 0)
    var explosion = Explosion.new(explosionPos)
    get_parent().add_child(bullet)
    get_parent().add_child(explosion)

func _on_screen_entered() -> void:
  on_screen = true

func _on_screen_exited() -> void:
  on_screen = false
