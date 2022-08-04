extends Area2D

const bullet = preload('res://Objects/Enemies/Lava Lotus Bullet.tscn')
const bullets: Array = [
  Vector2(-0.275, -0.20),
  Vector2(-0.15, -0.375),
  Vector2(0, -0.50),
  Vector2(0.15, -0.375),
  Vector2(0.275, -0.20)
]
var rng = RandomNumberGenerator.new()

var i: int = 0
onready var time = get_tree().create_timer(0)

func _ready():
  rng.randomize()
# warning-ignore:return_value_discarded
  connect('body_entered',self,"_on_body_enter")

func _process(_delta):
  var id_overlaps = Global.Mario.get_node_or_null('InsideDetector').get_overlapping_areas()
  if id_overlaps and id_overlaps.has(self):
    Global._ppd()

func new_bullet() -> void:
  if $AnimatedSprite.animation == 'launch': $AnimatedSprite.animation = 'default'
  if i != 2 and rng.randf() > 0.8: return
  var ball = bullet.instance()
  ball.velocity = bullets[i]
  ball.position.x = rng.randf_range(-8, 8)
  add_child(ball)
  return

func launch_bullets() -> void:
  var nodes = get_children()
  for node in nodes:
    if node is Area2D and !node.moving:
      node.moving = true
      node.position.x = 0
  i = -2
  $AnimatedSprite.animation = 'launch'
  return

func getInfo() -> String:
  return 'name: {n}\ni: {i}'.format({'i':i,'n':self.get_name()}).to_lower()

func _on_body_enter(a: Node) -> void:
  if a.is_class('KinematicBody2D') and a.has_method('explode'):
    a.explode()

func _on_Timer_timeout() -> void:
  if i >= 0:
# warning-ignore:standalone_ternary
    new_bullet() if i < 5 else launch_bullets()
  i += 1
