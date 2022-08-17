extends Area2D

var target_pos_y: float
var velocity: Vector2

onready var rng = RandomNumberGenerator.new()
var rand_y: int

func _ready():
  rng.randomize()
  if !rand_y:
    rand_y = rng.randi_range(-1, 1)
  if !target_pos_y:
    target_pos_y = position.y
  if !velocity:
    velocity.x = 4

func _process(delta):
  position += velocity * Global.get_delta(delta)
  $AnimatedSprite.flip_h = velocity.x < 0

  if position.y > target_pos_y + (rand_y * 32):
    position.y -= 4 * Global.get_delta(delta)
  elif position.y < target_pos_y + (rand_y * 32):
    position.y += 4 * Global.get_delta(delta)
  # Correcting the position because fuck my life
  if (
    position.y > target_pos_y + (rand_y * 32) - 3 and
    position.y < target_pos_y + (rand_y * 32) + 3
    ):
      position.y = target_pos_y + (rand_y * 32)

func kill(_a = false, _b = false, _c = false, _d = false, _e = false):
  return

func _on_area_entered(area):
  if area.is_in_group('Mario'):
    Global._ppd()
  if area.is_in_group('Projectile') and area.has_method('bounce') and area.belongs == 0 and area.bounce_count < 3:
    area.bounce()
    area.skip_frame = true
    area.get_node('Bounce').play()

func _on_body_entered(body):
  if body.is_in_group('Projectile') and body.has_method('explode') and body.belongs == 0:
    body.explode()