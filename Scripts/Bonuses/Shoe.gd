extends Node2D

enum TYPES {
  GREEN
  RED
}
export(TYPES) var type = TYPES.GREEN

var is_free: bool = true
var dead: bool = false
var velocity := Vector2.ZERO

func _ready():
  pass

func _process(delta):
  if dead:
    position += velocity * Global.get_vector_delta(delta)
    velocity.y += 0.4 * Global.get_delta(delta)
    return
  if is_free:
    if !Global.Mario.is_in_shoe and Global.is_mario_collide_area('BottomDetector', $Area2D):
      get_inside()
  else:
    $AnimatedSprite.global_transform = Global.Mario.get_node('Sprite').global_transform
    $AnimatedSprite.flip_h = Global.Mario.get_node('Sprite').flip_h
    if Global.state == 0:
      $AnimatedSprite.global_position.y = Global.Mario.get_node('Sprite').global_position.y + 16

func get_inside():
  is_free = false
  Global.Mario.bind_shoe(get_instance_id())
  Global.play_base_sound('ENEMY_Stomp')
  Global.Mario.get_node('AnimationPlayer').play('Small' if Global.state == 0 else 'Big')
  z_index = 11

func hit():
  dead = true
  velocity = Vector2(2 if $AnimatedSprite.flip_h else -2, -8)
  $AnimatedSprite.flip_v = true

func stomp():
  $stomp.play()
  if Input.is_action_pressed('mario_jump'):
    Global.Mario.velocity.y = -700
  else:
    Global.Mario.velocity.y = -450
  var explosion = preload('res://Scripts/Effects/StompEffect.gd').new(Global.Mario.position)
  get_parent().add_child(explosion)
