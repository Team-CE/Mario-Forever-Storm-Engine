extends KinematicBody2D
class_name AliveObject

const multiplier_scores = [100, 200, 500, 1000, 2000, 5000, 1]

enum DEATH_TYPE {
  BASIC,
  FALL,
  SHELL,            # Requires "Shell Stopped" and "Shell Moving" animations.
  DISAPPEAR
}

export var vars: Dictionary = {"speed":50.0, "bounce":5}
export var AI:Script

export var gravity_scale: float = 1
export var score: int           = 100
export var smart_turn: bool
export var invincible: bool
export var ignore_all: bool #temporary
export(float,-1,1) var dir: float = -1

#RayCasts leave empty if smart_turn = false
export var ray_L_pth: NodePath
export var ray_R_pth: NodePath
export var sound_pth: NodePath
export var animated_sprite_pth: NodePath

var ray_L: RayCast2D
var ray_R: RayCast2D
var animated_sprite: AnimatedSprite
var sound: AudioStreamPlayer2D

var velocity: Vector2
var alive: bool = true
var death_type:int

onready var first_pos: Vector2 = position #For pirahna plant and other enemies
onready var brain: Brain = Brain.new()      #Shell for AI

func _ready() -> void:
  if ray_L_pth.is_empty() || ray_R_pth.is_empty(): #Ray casts init
    smart_turn = false
  else:
    ray_L = get_node(ray_L_pth)
    ray_R = get_node(ray_R_pth)
  
  if !sound_pth.is_empty():  #Sound player init
    sound = get_node(sound_pth)
    
  if animated_sprite_pth.is_empty():  #Animated sprite init
    push_warning('[CE WARNING] Cant load Animated sprite at:'+str(self))
  else:
    animated_sprite = get_node(animated_sprite_pth)
  
  brain.name = 'Brain'  #Brain init
  add_child(brain)
  if AI != null:  #AI init
    brain.set_script(AI)
    brain._setup(self)
  else:
    printerr('[CE ERROR] AliveObject'+str(self)+' is brainless!')

func _physics_process(delta:float) -> void:
  if !alive:
    return
    
  brain._ai_process(delta)
  if position.y > Global.currlevel.death_height:
    queue_free()
  #Fixing ceiling collision and is_on_floor() flickering
  if is_on_floor() || is_on_ceiling():
    velocity.y = 1
  
  velocity = move_and_slide(velocity,Vector2.UP)

#Useful functions
func turn()->void:
  dir = -dir
  velocity.x = vars["speed"] * dir

func on_edge() -> bool:
  return ray_L.is_colliding() || ray_R.is_colliding()

# warning-ignore:shadowed_variable
func kill(death_type: int= 0) -> void:
  alive = false
  collision_layer = 0
  collision_mask = 0
  match death_type:       #TEMP
    DEATH_TYPE.BASIC:
      sound.play()
      animated_sprite.set_animation('dead')
      velocity.x = 0
      get_parent().add_child(ScoreText.new(score, position))
      yield(get_tree().create_timer(2.0), 'timeout')
    DEATH_TYPE.DISAPPEAR:
      pass
    DEATH_TYPE.FALL:
      pass
    DEATH_TYPE.SHELL:
      pass
  queue_free()
