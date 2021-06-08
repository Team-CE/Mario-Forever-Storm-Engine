extends KinematicBody2D
class_name AliveBody, "res://GFX/Editor/AliveBody.png"

enum DIRECTION{
  LEFT  = -1,
  RIGHT = 1,
  UP    = -2,
  DOWN  = 2
}

enum HIT_TYPE{
  STOMP,
  SHELL,
  DEATH
}

enum DEATH_TYPE {
  STOMP,      #Stomp like goomba
  FALL,       #Fall = Death from shell
  DISAPPEAR   #Just Disappear
}

enum THROW_TYPE{
  NONE = -1,  #Does not throw
  SINGLE,     #Throw one project tile
  SPAM,       #Throws a lot of projectiles
  RARE        #Throw YareYareDaze
}

enum AI_TYPE{
  IDLE,
  WALK,
  FLY,        
  PIRANHA,    #Пиранха плент B
  HAMMERBRO   #BRO
}

signal on_collide_with_player # Call when player touch it / Звоните, когда игрок прикоснется к нему
signal on_death               # Call when DEAD / Позвони, когда УМРЕШЬ

# Private variables
var velocity: Vector2 = Vector2.ZERO
var gravity: float = Global.gravity
var dead: bool = false

# Enumerable variables
export(DIRECTION) var DIR: int = DIRECTION.LEFT
export(DEATH_TYPE) var KILL_AS: int = DEATH_TYPE.FALL
export(THROW_TYPE) var PROJECTILE_THROW_TYPE: int = THROW_TYPE.NONE

# Public variables
export var speed: float = 50                    # Gotta go fast
export var smart_turn: bool = false             # Big brain 
export var has_gravity: bool = true             # HASEGRAVITY
export var reward: int = 100                    # Gives specified score after death
export var jumping: bool = false                # For jumping enemies or powerups
export(PackedScene) var projectile: PackedScene # Project "Tile"

#Technical variables
onready var sprite: AnimatedSprite = AnimatedSprite.new()

# Built-in functions
func _ready()-> void: # YOU CAN OVERWRITE IT
  if connect("on_death", Global, "add_score", [ ], CONNECT_ONESHOT) != OK:
    printerr("[AliveBody]: Can't connect signal to GLOBAL.add_score()")
  gravity *= float(has_gravity)

func _physics_process(_delta: float) -> void: # DO NOT OVERWRITE IT
  if !is_on_floor():
    velocity.y += gravity
  
  if !dead:                 #If it die
    if is_on_wall():
      DIR = -DIR
      velocity.y += 2 * DIR

    gravity *= float(has_gravity)
    _process_alive(_delta)
    if is_on_ceiling():
      velocity.y = 2
    velocity = move_and_slide(velocity)
    return
  _process_dead(_delta)

func _process_alive(_delta:float) -> void:  # YOU CAN OVERWRITE IT
  pass

func _process_dead(_delta:float) -> void:   # YOU CAN OVERWRITE IT
  pass

func _kill(killer: Node2D,death_type: int) -> void: # DO NOT OVERWRITE IT
  dead = true
  emit_signal("on_death", reward)
  _on_death(killer,death_type)

func _on_death(killer: Node2D,death_type: int) -> void: # YOU CAN OVERWRITE IT
  pass
