extends Brain

var camera = Global.Mario.get_node('Camera')

var inited_throwable
var inited_lakitu_addon

var internal_result
var custom_result_added: bool = false

var xspeed: float = 0
var throw_counter: float = 0
var blink_counter: float = 0
var throw_start: bool = false
var throw_was_activated: bool = false
var odchowanie: bool = false
var is_blinking: bool = false

var rng = RandomNumberGenerator.new()

func _ready_mixin() -> void:
  owner.velocity_enabled = false
  owner.death_type = AliveObject.DEATH_TYPE.FALL
  rng.randomize()
  
  var children = owner.get_parent().get_children()
  for node in range(len(children)):
    if 'AI' in children[node]:
      owner.add_collision_exception_with(children[node])
  
  if owner.vars['lakitu_addon']:
    inited_lakitu_addon = owner.vars['lakitu_addon'].new()
  
func _setup(b) -> void:
  ._setup(b)

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  
  if !owner.alive or owner.frozen:
    owner.velocity_enabled = true
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    owner.get_node('CollisionShape2D2').disabled = false
    owner.get_node('CollisionShape2D').disabled = true
    return
  
  if !owner.frozen:
    if inited_lakitu_addon and inited_lakitu_addon.has_method('_process_lakitu'):
      inited_lakitu_addon._process_lakitu(self, delta)
    
    if blink_counter < 10:
      blink_counter += 1 * Global.get_delta(delta)
    else:
      blink_counter = 0
      
      if !is_blinking and !throw_was_activated:
        var random: int = rand_range(0, 10)
        if random > 8:
          is_blinking = true
          owner.animated_sprite.animation = 'blink lola'
          owner.animated_sprite.frame = 0
        if random < 2:
          is_blinking = true
          owner.animated_sprite.animation = 'blink chmurona'
          owner.animated_sprite.frame = 0
      
    if (
        owner.animated_sprite.frame == 15 and owner.animated_sprite.animation == 'blink lola') or (
        owner.animated_sprite.frame == 11 and owner.animated_sprite.animation == 'blink chmurona'
      ):
      owner.animated_sprite.animation = 'default'
    
    owner.position.x += xspeed * Global.get_delta(delta)
    
    if (!Global.Mario.dead and Global.Mario.position.x < camera.limit_right - owner.vars['px_before_leaving']):
      if Global.is_getting_closer(-32, owner.position):
        throw_counter += 1 * Global.get_delta(delta)
      
      if throw_counter > owner.vars['throw_delay']:
        if !throw_was_activated:
          owner.animated_sprite.animation = 'chowanie'
          throw_was_activated = true
        elif throw_counter > owner.vars['throw_delay'] + 30:
          if !odchowanie:
            owner.animated_sprite.animation = 'odchowanie'
            owner.animated_sprite.frame = 0
            odchowanie = true
          elif owner.animated_sprite.frame >= 11:
            throw_start = true
            odchowanie = false
            throw_counter = 0
            
      if throw_start:
        var nodes = [owner.get_node('Throw1'), owner.get_node('Throw2'), owner.get_node('Throw3')]
        var mnode = nodes[rng.randi_range(0, 2)] as AudioStreamPlayer2D
        mnode.play()
    
        throw_was_activated = false
        throw_start = false
        is_blinking = false
        inited_throwable = owner.vars['throw_script'].instance()
        if internal_result:
          inited_throwable.vars['result'] = internal_result
          print('set result')
          if custom_result_added:
            print('clear var')
            custom_result_added = false
            internal_result = null
        inited_throwable.position = owner.position + Vector2(0, -16)
        inited_throwable.velocity.y = -200
        get_parent().get_parent().add_child(inited_throwable)
        var children = inited_throwable.get_parent().get_children()
        for node in range(len(children)):
          if 'AI' in children[node]:
            inited_throwable.add_collision_exception_with(children[node])
    
      # Limit speed
      if Global.is_getting_closer(-64, owner.position):
        if xspeed < -12:
          xspeed += 0.4 * Global.get_delta(delta)
        if xspeed > 12:
          xspeed -= 0.4 * Global.get_delta(delta)
      # Movement
      if owner.position.x > Global.Mario.position.x + 50:
        xspeed -= 0.2 * Global.get_delta(delta)
      if owner.position.x < Global.Mario.position.x - 50:
        xspeed += 0.2 * Global.get_delta(delta)
        
      if (
          owner.position.x < Global.Mario.position.x + 100 and
          owner.position.x > Global.Mario.position.x and
          xspeed < -2 and
          Global.Mario.velocity.x >= 0
        ):
        xspeed += 1 * Global.get_delta(delta)
      if (
          owner.position.x < Global.Mario.position.x and
          owner.position.x > Global.Mario.position.x - 100 and
          xspeed > 4 and
          Global.Mario.velocity.x <= 0
        ):
        xspeed -= 1 * Global.get_delta(delta)
    elif xspeed > -2:
      xspeed -= 1 * Global.get_delta(delta) # Will fly away if player is dead or is near the finish
  else:
    xspeed = 0
    
  if is_mario_collide('BottomDetector') and !owner.frozen and Global.Mario.position.y < owner.position.y - 32 and Global.Mario.velocity.y > 0:
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50

func _on_any_death():
  var node = Node.new()
  node.script = preload('res://Scripts/Enemies/NewLakitu.gd')
  node.throw_script = owner.vars['throw_script']
  node.throw_delay = owner.vars['throw_delay']
  node.lakitu_addon = owner.vars['lakitu_addon']
  if node.result: node.result = internal_result
  owner.get_parent().add_child(node)
