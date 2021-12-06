extends Brain

var camera = Global.Mario.get_node('Camera')

export var px_before_leaving = 1000
export var throw_delay = 200

var xspeed: float = 0
var throw_counter: int = 0
var blink_counter: int = 0
var throw_activated: bool = false
var is_blinking: bool = false

func _ready_mixin():
  owner.velocity_enabled = false
  owner.death_type = AliveObject.DEATH_TYPE.FALL

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  
  if !owner.alive:
    owner.velocity_enabled = true
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    return
  
  if !owner.frozen:
    print(blink_counter)
    if blink_counter < 10:
# warning-ignore:narrowing_conversion
      blink_counter += 1 * Global.get_delta(delta)
    else:
      blink_counter = 0
    
      var random: int = rand_range(1, 10)
      
      if random > 9 and !is_blinking:
        is_blinking = true
        owner.animated_sprite.animation = 'blink lola'
      if random < 2 and !is_blinking:
        is_blinking = true
        owner.animated_sprite.animation = 'blink chmurona'
      
    if (!owner.animated_sprite.playing):
      is_blinking = false
    if !Global.is_getting_closer(-64, owner.position):
      throw_counter += 1 * Global.get_delta(delta)
    
    if throw_counter > throw_delay:
      var throw_was_activated: bool = false
      owner.animated_sprite.animation = 'chowanie'
      throw_was_activated = true
      
      throw_counter = 0
    
      if throw_activated:
        owner.animated_sprite.animation = 'idle'
        owner.get_node('Throw' + str(int(rand_range(1, 3)))).play()
        throw_was_activated = true
        throw_activated = false
        #inited_throwable.throw(self)
    
    owner.position.x += xspeed * Global.get_delta(delta)
    
    if (!Global.Mario.dead and Global.Mario.position.x < camera.limit_right - px_before_leaving):
      # Limit speed
      if !Global.is_getting_closer(-64, owner.position):
        if xspeed < -10:
          xspeed += 0.4
        if xspeed > 10:
          xspeed -= 0.4
      # Movement
      if owner.position.x > Global.Mario.position.x + 50:
        xspeed -= 0.2
      if owner.position.x < Global.Mario.position.x - 50:
        xspeed += 0.2
        
      if (
        owner.position.x < Global.Mario.position.x + 100 and
        owner.position.x > Global.Mario.position.x and
        xspeed < -2 and
        Global.Mario.velocity.x >= 0
        ):
        xspeed += 1
      if (
        owner.position.x < Global.Mario.position.x and
        owner.position.x > Global.Mario.position.x - 100 and
        xspeed > 4 and
        Global.Mario.velocity.x <= 0
        ):
        xspeed -= 1
    elif xspeed > -2:
      xspeed -= 1 # Will fly away if player is dead or is near the finish
  else:
    xspeed = 0
    
  if is_mario_collide('BottomDetector') and !owner.frozen and Global.Mario.velocity.y > 0:
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50

func _on_any_death():
  var node = Node.new()
  node.script = preload('res://Scripts/Enemies/NewLakitu.gd')
  owner.get_parent().add_child(node)
