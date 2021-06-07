extends KinematicBody2D
class_name AliveBody

enum DIRECTION{
  LEFT  = -1,
  RIGHT = 1,
  UP    = 2,
  DOWN  = 3
}

enum HIT_TYPE{
  STOMP,
  SHELL,
  DEATH
}

enum DEATH_TYPE {
  BASIC,
  FALL,       #Fall = Death from shell
  DISAPPEAR
}

signal on_collide_with_player
signal on_death
signal on_hit

#Technical variables
var death_type #SETS ONLY FROM SCRIPT

#Private variables
var velocity: Vector2 = Vector2.ZERO
var gravity: float = Global.gravity
var dead: bool = false

#Enumerable variables
export(DIRECTION) var DIR: int
export(HIT_TYPE)  var HIT: int
export(DEATH_TYPE) var kill_as: int = DEATH_TYPE.FALL

#Public variables
export var speed: float = 50
export var smart_turn: bool = false
export var has_gravity:bool = true  
export var revard: int = 100        #Gives a score for player after death
export var jumping: bool = false    #For jumping enemies or power ups

#Built-in functions
func _ready()-> void:
  if connect("on_death",Global,"add_score",[ ],CONNECT_ONESHOT) != OK:
    printerr("Can't connect signal to GLOBAL.add_score().")
  gravity *= float(has_gravity)

func _physics_process(_delta:float) -> void:
  if !is_on_floor():
    velocity.y += gravity
  
  if !dead:
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

func _process_alive(_delta:float) -> void:
  pass

func _process_dead(_delta:float) -> void:
  pass

func _kill(killer: Node2D):
  dead = true
  emit_signal("on_death", revard)


