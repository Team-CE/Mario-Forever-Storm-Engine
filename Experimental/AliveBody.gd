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

signal on_collide_with_player
signal on_death
signal on_hit

#technical variables


#Private variables
var velocity: Vector2 = Vector2.ZERO
var gravity: float = Global.gravity
var dead: bool = false

#Enumerable variables
export(DIRECTION) var DIR: int
export(HIT_TYPE)  var HIT: int

#Public variables
export var speed: float = 50
export var smart_turn: bool = false
export var has_gravity:bool = true  
export var revard: int = 100        #Gives a score for player after death

#Built-in functions
func _ready()-> void:
  if connect("on_death",Global,"add_score",[ ],CONNECT_ONESHOT) != OK:
    printerr("Can't connect signal to GLOBAL.add_score().")
  gravity *= float(has_gravity)

func _physics_process(_delta:float) -> void:
  if !dead:
    _process_alive(_delta)
    return
  _process_dead(_delta)

func _process_alive(_delta:float) -> void:

  pass

func _process_dead(_delta:float) -> void:
  pass

func _kill() -> void:
  dead = true
  emit_signal("on_death", revard)

