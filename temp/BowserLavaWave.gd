extends Area2D

var velocity: float = 0
var force = 0
var height = 0
var target_height = 0

var index = 0
var motion_factor = 0.015
var collided_with = null

signal splash

func wave_update(spring_constant, dampening, delta):
  height = position.y
  
  var x = height - target_height
  var loss = -dampening * velocity
  
  #hooke's law:
  force = - spring_constant * x + loss
  
  velocity += force * Global.get_delta(delta) / 3
  position.y += velocity * Global.get_delta(delta)

func initialize(x_position, id):
  height = position.y
  target_height = position.y
  velocity = 0
  position.x = x_position
  index = id

func _on_BowserLavaSingle_body_entered(body):
  if body == collided_with:
    return
  if body.get_node_or_null('Brain') and body.get_node('Brain').has_method('lava_love'):
    print(index)
    #the body is the last thing this spring collided with
    collided_with = body
    var speed = 10
    emit_signal('splash', index, speed)
    body.get_node('Brain').lava_love()
