extends Area2D


export var jump_strength: float = -10 #setget reset_height
export var timer: float = 250 #setget reset_timer
export var time_offset: float = 0

var counter: float = 0
var active: bool = false
var velocity := Vector2.ZERO
onready var firstpos = position

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
    position += velocity.rotated(rotation) # start y = -12.8
    velocity += Vector2(0, 0.2) * Global.get_delta(delta)
    $AnimatedSprite.flip_v = velocity.y > 0.2
    if velocity.y > 0.2 and position >= firstpos:
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

  $CollisionShape2D.disabled = !active
  var id_overlaps = Global.Mario.get_node_or_null('InsideDetector').get_overlapping_areas()
  if id_overlaps and id_overlaps.has(self):
    Global._ppd()
      
func reset_height(new_height):
  counter = 0
  jump_strength = new_height

func reset_timer(new_timer):
  counter = 0
  timer = new_timer
