var isActivated: bool = false
var flyingDown: bool = false
var prevVelocity: float = 0

func _ready_mixin(_mario):
  flyingDown = false
  isActivated = false
  prevVelocity = false

func _process_mixin_physics(mario, delta):
  if flyingDown:
    var collides = mario.get_node('BottomDetector').get_overlapping_bodies()
    for i in collides:
      if i.has_method('hit'):
        i.hit(delta, false, false)

func _process_mixin(mario, delta):
  if Global.Mario.movement_type != Global.Mario.Movement.DEFAULT:
    _ready_mixin(mario)
    return
  
  if Input.is_action_just_pressed('mario_jump') and not isActivated and not mario.is_on_floor() and Global.Mario.controls_enabled:
    isActivated = true
    mario.velocity.y = -650
    mario.allow_custom_animation = true
    Global.play_base_sound('MISC_PropellerFly')
  
  mario.get_node('BottomDetector/CollisionBottom').scale.y = 0.5
  
  if isActivated:
    #mario.get_node('Sprite').animation = 'Launching'
    mario.animate_sprite('Launching')
    
    if Input.is_action_just_pressed('mario_crouch') and not flyingDown:
      flyingDown = true
      Global.play_base_sound('MISC_PropellerDown')
      var collides = mario.get_node('BottomDetector').get_overlapping_bodies()
      for i in collides:
        if i.has_method('hit'):
          i.hit(delta, false, false)
    
    if not flyingDown:
      if mario.velocity.y > 250:
        mario.velocity.y = 250
      if mario.velocity.y < 0:
        mario.velocity.y -= 10 * Global.get_delta(delta)
# warning-ignore:incompatible_ternary
      mario.get_node('Sprite').speed_scale = 2.5 if mario.velocity.y < 0 else 1
    else:
      mario.velocity.y = 950
      mario.get_node('Sprite').speed_scale = 2.5
      mario.get_node('BottomDetector/CollisionBottom').position.y = mario.velocity.y / 25 * Global.get_delta(delta)
      mario.get_node('BottomDetector/CollisionBottom').scale.y = 6

  if mario.is_on_floor():
    if Input.is_action_pressed('mario_crouch'):
      mario.can_jump = false
    isActivated = false
    flyingDown = false
    mario.allow_custom_animation = false
      
  #prevVelocity = mario.velocity.y
  
  
