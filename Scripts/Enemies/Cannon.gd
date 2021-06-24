extends StaticBody2D
class_name Cannon, "res://GFX/Editor/Enemy.png"

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var on_screen: bool
var counter: float = 0

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
    var explosion = Explosion.new(position)
    get_parent().add_child(explosion)
    var bullet = load('res://Objects/Enemies/Bullet.tscn').instance()
    bullet.position = Vector2(position.x, position.y + 16)
    bullet.dir = -1 if Global.Mario.position.x < position.x else 1
    get_parent().add_child(bullet)

func _on_screen_entered() -> void:
  on_screen = true

func _on_screen_exited() -> void:
  on_screen = false
