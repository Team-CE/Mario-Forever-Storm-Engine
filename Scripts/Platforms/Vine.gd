extends Area2D


#onready var mario = Global.Mario
#
#func _process(_delta):
#  if (
#      (Input.is_action_just_pressed('mario_up') or
#      (Input.is_action_just_pressed('mario_crouch') and
#      not mario.is_on_floor())) and
#      mario.is_over_vine() and
#      not mario.movement_type == mario.Movement.CLIMBING
#    ):
#    mario.controls_enabled = false
#    mario.animation_enabled = false
#    mario.movement_type = mario.Movement.CLIMBING
