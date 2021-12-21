class_name PropellerAction

var isActivated: bool = false
var flyingDown: bool = false

func _process_mixin(mario, delta):
  if Input.is_action_just_pressed('mario_jump') and not isActivated and not mario.is_on_floor() and Global.Mario.controls_enabled:
    isActivated = true
    mario.velocity.y = -650
    mario.allow_custom_animation = true
    Global.play_base_sound('MISC_PropellerFly')
  
  if isActivated:
    mario.get_node('Sprite').animation = 'Launching'
    
    if Input.is_action_just_pressed('mario_crouch') and not flyingDown:
      flyingDown = true
      Global.play_base_sound('MISC_PropellerDown')
    
    if not flyingDown:
      if mario.velocity.y > 250:
        mario.velocity.y = 250
      if mario.velocity.y < 0:
        mario.velocity.y -= 10 * Global.get_delta(delta)
      mario.get_node('Sprite').speed_scale = 2.5 if mario.velocity.y < 0 else 1
    else:
      mario.velocity.y = 950
      mario.get_node('Sprite').speed_scale = 2.5

  if mario.is_on_floor():
    isActivated = false
    flyingDown = false
    mario.allow_custom_animation = false
  
  
