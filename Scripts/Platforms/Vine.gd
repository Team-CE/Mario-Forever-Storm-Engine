extends Area2D


var isClimbing: bool
onready var mario = Global.Mario

func _process(_delta):
  if (Input.is_action_just_pressed('mario_up') or (Input.is_action_just_pressed('mario_crouch') and not mario.is_on_floor())) and !isClimbing and col():
    mario.controls_enabled = false
    mario.animation_enabled = false
    mario.allow_custom_movement = true
    isClimbing = true
  if isClimbing:
    movement_climbing()

func movement_climbing():
  if not col():
    isClimbing = false
    mario.animation_enabled = true
    mario.controls_enabled = true
    mario.allow_custom_movement = false
  
  if Input.is_action_pressed('mario_crouch'):
    if mario.is_on_floor():
      isClimbing = false
      mario.animation_enabled = true
      mario.controls_enabled = true
      mario.allow_custom_movement = false
    else:
      mario.velocity.y = 100
  if Input.is_action_pressed('mario_up'):
    mario.velocity.y = -100
  if Input.is_action_pressed('mario_left'):
    mario.velocity.x = -100
  if Input.is_action_pressed('mario_right'):
    mario.velocity.x = 100
    
func col() -> bool:
  var overlaps = get_overlapping_bodies()
  for c in overlaps:
    if c.get_name() == 'Mario':
      return true
  return false
