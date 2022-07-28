extends Area2D


export var jump_strength: float = -10 #setget reset_height
export var timer: float = 250 #setget reset_timer
export var time_offset: float = 0

#export var 

var counter: float = 0
var active: bool = false
var velocity := Vector2.ZERO
onready var firstpos = position

var inv_counter: float = 10

func _ready():
  if Engine.editor_hint:
    pass
    #$Path2D.curve.add_point()
  else:
    z_index = 0
    counter = timer - time_offset

func _process(delta):
  #if Engine.editor_hint: return
  counter += 1 * Global.get_delta(delta)
  if active:
    
    
    position += velocity.rotated(rotation) * Global.get_vector_delta(delta) # start y = -12.8
    velocity += Vector2(0, 0.2) * Global.get_delta(delta)
    $AnimatedSprite.flip_v = velocity.y > 0.2
    #if velocity.y > 0.2 and velocity.y < 5 and Global.is_getting_closer(-256, position) and !shit and position.rotated(rotation).y >= firstpos.rotated(rotation).y:
    #  print(str(position.rotated(rotation).y) + ' >= ' + str(firstpos.rotated(rotation).y) + ': ' + self.name)
    #  shit = true
    if velocity.y > 0.2 and ((
      (rotation_degrees >= 300 or
        rotation_degrees <= 240 and
        (rotation_degrees > 120 or rotation_degrees < 60)
      ) and
      position.rotated(rotation).y >= firstpos.rotated(rotation).y) or (
      (rotation_degrees < 300 and 
      (rotation_degrees > 240 or (rotation_degrees <= 120 and rotation_degrees >= 60))) and
      position.rotated(rotation).x >= firstpos.rotated(rotation).x)
      ):
      active = false
      #var splash = LavaEffect.new(position - Vector2(0, 32).rotated(rotation), rotation)
      #var splash = Explosion.new(position - Vector2(0, 32).rotated(rotation))
      var splash = preload('res://Scripts/Effects/LavaEffect.gd').new(position - Vector2(0, 32).rotated(rotation), rotation)
      get_parent().add_child(splash)
      position = firstpos

  elif counter > timer: # Launching
    active = true
    velocity.y = jump_strength
    counter = 0
  
  visible = active
  if inv_counter < 10:
    inv_counter += 1 * Global.get_delta(delta)

  $CollisionShape2D.disabled = !active
  if Global.Mario.is_in_shoe and Global.Mario.shoe_type == 1:
    if Global.is_mario_collide_area('BottomDetector', self) and Global.Mario.velocity.y > 0:
      velocity += Vector2(0, 5).rotated(-rotation)
      inv_counter = 0
      Global.Mario.shoe_node.stomp()
      return
    elif Global.is_mario_collide_area('InsideDetector', self) and velocity.y > -8 and inv_counter > 8:
      Global._ppd()
  else:
    if Global.is_mario_collide_area('BottomDetector', self):
      Global._ppd()
      
func reset_height(new_height):
  counter = 0
  jump_strength = new_height

func reset_timer(new_timer):
  counter = 0
  timer = new_timer
