tool
extends Node2D


var counter: float = 0
var dir: bool = false
var dead: bool = false

export var radius: float = 150 setget reset_offset
export var speed: float = 2 setget reset_speed
export var flower_movement: bool = false setget reset_flower
export var angle: float = 0 setget reset_angle
export var flower_speed: float = 5
export var instant_kill: bool = false

func _ready() -> void:
  if not flower_movement:
    $Node2D/AnimatedSprite.position.y = 0 - radius
  $Node2D.rotation_degrees += angle
  
  if Engine.editor_hint: return
  $Node2D/AnimatedSprite/Light2D.visible = true

func _process(delta) -> void:
  if dead:
    return
  if flower_movement:
    counter += flower_speed * get_delta(delta)
    if counter >= radius:
      counter = 0
      if dir:
        $Node2D/AnimatedSprite.position.y = 0
      dir = !dir
    
    $Node2D/AnimatedSprite.position.y += (flower_speed if dir else 0 - flower_speed) * get_delta(delta)
  
  $Node2D.rotation += (speed / 100) * get_delta(delta)
  $Node2D/AnimatedSprite.global_rotation = 0
  
  if Engine.editor_hint:
    return
  
  if Global.Mario.is_in_shoe and Global.Mario.shoe_type == 1:
    if Global.is_mario_collide_area('BottomDetector', $Node2D/AnimatedSprite/Area2D):
      #var splash = preload('res://Scripts/Effects/LavaEffect.gd').new(position, Global.Mario.rotation)
      #get_parent().add_child(splash)
      #splash.global_position = $Node2D/AnimatedSprite.global_position
      
      # Lava particles
      var lavap = preload('res://Objects/Effects/LavaParticles.tscn').instance()
      lavap.preprocess = 0
      get_parent().add_child(lavap)
      lavap.global_position = $Node2D/AnimatedSprite.global_position
      lavap.process_material.emission_box_extents = Vector3(8, 12, 0)
      var timer = Timer.new()
      timer.autostart = true
      timer.wait_time = 0.3
      timer.connect('timeout', lavap, 'set', ['emitting', false])
      timer.one_shot = true
      lavap.add_child(timer)
      
      var score = ScoreText.new(1000, $Node2D/AnimatedSprite.global_position)
      get_parent().add_child(score)
      dead = true
      $Node2D.queue_free()
      Global.Mario.shoe_node.stomp()
      return
    elif Global.is_mario_collide_area('InsideDetector', $Node2D/AnimatedSprite/Area2D):
      kill_mario()
  elif Global.is_mario_collide_area('InsideDetector', $Node2D/AnimatedSprite/Area2D):
    kill_mario()

func kill_mario() -> void:
  if !instant_kill:
    Global._ppd()
  else:
    Global._pll()

func reset_offset(new_offset):
  radius = new_offset
  $Node2D/AnimatedSprite.position.y = 0 - radius

func reset_flower(new_bool):
  flower_movement = new_bool
  $Node2D.rotation_degrees = angle
  counter = 0
  dir = false
  $Node2D.rotation = 0
# warning-ignore:incompatible_ternary
  $Node2D/AnimatedSprite.position.y = 0 if flower_movement else 0 - radius
  return

static func get_delta(delta) -> float:       # Delta by 50 FPS
  return 50 / (1 / (delta if not delta == 0 else 0.0001))

func reset_speed(new_speed):
  speed = new_speed
  reset_all()
  return

func reset_angle(new_angle):
  angle = new_angle
  reset_all()
  return

func reset_all() -> void:
  var parent = get_parent()
  if parent and parent.has_method('get_children'):
    var children = parent.get_children()
    for node in children:
      if node.has_method('reset_offset'):
        node.get_node('Node2D').rotation_degrees = node.angle
  return
