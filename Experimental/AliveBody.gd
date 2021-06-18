tool  
extends KinematicBody2D
class_name AliveBody, "res://GFX/Editor/AliveBody.png"

enum DIRECTION {
  LEFT  = -1,
  RIGHT = 1,
  UP    = -2,
  DOWN  = 2
}

enum HIT_TYPE {
  STOMP,
  SHELL,
  DEATH
}

enum DEATH_TYPE {
  STOMP,
  FALL,
  DISAPPEAR
}

enum BEHAVIOR_TYPE {
  IDLE,
  WALK,
  CUSTOM
}

signal on_death # Called when body dies

# Private variables
var velocity: Vector2 = Vector2.ZERO
var gravity: float = Global.gravity
var dead: bool = false

# Enumerable variables
export(DIRECTION) var dir: int = DIRECTION.LEFT
export(DEATH_TYPE) var death_type: int = DEATH_TYPE.FALL
export(BEHAVIOR_TYPE) var BEHAVIOR: int = BEHAVIOR_TYPE.WALK

# Public variables
export var speed: float = 50
export var alt_speed: float = 250               # Shell speed
export var smart_turn: bool = false             # Red koopa movement
export var has_gravity: bool = true
export var reward: int = 100                    # Gives specified score after death
export var jumping: bool = false                # For jumping enemies or powerups
export(PackedScene) var projectile: PackedScene

# Technical variables


# Built-in functions
func _ready() -> void: # YOU CAN OVERWRITE IT
  if is_instance_valid($Ray):
    $Ray.position.x = $Ray.position.x * dir
  if connect("on_death", Global, "add_score", [ ], CONNECT_ONESHOT) != OK:
    printerr("[AliveBody]: Can't connect signal to GLOBAL.add_score()")
  gravity *= float(has_gravity)

func _physics_process(_delta: float) -> void: # DO NOT OVERWRITE IT
  if Engine.editor_hint:
    return
  if !is_on_floor():
    velocity.y += gravity
  
  if !dead:                 #If it die
    if is_on_wall():
      _turn()
    
    if smart_turn and is_instance_valid($Ray):
      if !$Ray.is_colliding():
        _turn()

    match BEHAVIOR:                   # Calls Behavior Functions
      BEHAVIOR_TYPE.IDLE:
        pass
      BEHAVIOR_TYPE.WALK:
        _Behavior_Walk(_delta)
      BEHAVIOR_TYPE.CUSTOM:
        _Behavior_Custom(_delta)

    gravity *= float(has_gravity)
    _process_alive(_delta)        # Called when alive
    if is_on_ceiling():
      velocity.y = 2

    velocity = move_and_slide(velocity,Vector2.UP)
    return
  _process_dead(_delta)

func _process_alive(_delta: float) -> void:  # YOU CAN OVERWRITE IT
  pass

func _process_dead(_delta: float) -> void:   # YOU CAN OVERWRITE IT
  pass

# _BEHAVIOR_ functions
func _Behavior_Walk(_delta: float) -> void:
  velocity.x = speed * dir
  pass

# Empty custom behavior
func _Behavior_Custom(_delta: float) -> void:
  pass

func _kill(killer: Node2D, death_type: int) -> void: # DO NOT OVERWRITE IT
  dead = true
  emit_signal("on_death", reward)
  _on_death(killer,death_type)

func _turn() -> void:
  dir = -dir
  velocity.y += 2 * dir
  if is_instance_valid($Ray):
    $Ray.position.x = -$Ray.position.x

func _on_death(killer: Node2D,death_type: int) -> void: # YOU CAN OVERWRITE IT
  pass

# func _get_configuration_warning() -> String:
#   return 'Need:[AnimationSprite]:"Sprite",[CollisionShape2D]:"Collision"'

