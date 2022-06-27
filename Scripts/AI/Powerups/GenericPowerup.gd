extends Brain

var appearing: bool = true
var appear_counter: float = 0

var initial_pos: Vector2
var offset_pos: Vector2 = Vector2.ZERO

var custom_script
var custom_appearing: bool = false

func _ready_mixin():
  owner.death_type = AliveObject.DEATH_TYPE.NONE
  owner.z_index = -5
  owner.velocity_enabled = false
  initial_pos = owner.position
  
  # Replacing with mushroom if mario is small and state is provided
  if 'set state' in owner.vars and 'from bonus' in owner.vars and Global.state == 0 and owner.vars['set state'] > 1:
    var mushroom = load('res://Objects/Bonuses/Powerups/Mushroom.tscn').instance()
    mushroom.position = owner.position
    mushroom.rotation = owner.rotation
    owner.get_parent().add_child(mushroom)
    owner.queue_free()
    
  if 'custom behavior' in owner.vars:
    custom_script = owner.vars['custom behavior'].new()
  
  if 'custom appearing' in owner.vars:
    custom_appearing = true
  
  var children = owner.get_parent().get_children()
  for node in range(len(children)):
    if children[node] is KinematicBody2D:
      owner.add_collision_exception_with(children[node])
      Global.Mario.ray_L.add_exception(owner)
      Global.Mario.ray_L_2.add_exception(owner)
      Global.Mario.ray_R.add_exception(owner)
      Global.Mario.ray_R_2.add_exception(owner)
  
func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  
  if !appearing and not ('sgr behavior' in owner.vars and owner.vars['sgr behavior']):
    if custom_script and custom_script.has_method('_process_movement'):
      custom_script._process_movement(self, delta)
    else:
      if !owner.is_on_floor():
        owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
      owner.velocity.x = owner.vars['speed'] * owner.dir
      if owner.is_on_wall():
        owner.turn()
  
  if !custom_appearing and not ('sgr behavior' in owner.vars and owner.vars['sgr behavior']):
    if appearing and appear_counter < 32:
      offset_pos -= Vector2(0, owner.vars['grow speed']).rotated(owner.rotation) * Global.get_delta(delta)
      appear_counter += owner.vars['grow speed'] * Global.get_delta(delta)
    elif appear_counter >= 32 and appear_counter < 100:
      offset_pos = Vector2(0, -32).rotated(owner.rotation)
      owner.position = initial_pos + offset_pos
      appearing = false
      appear_counter = 100
      owner.z_index = 1
      owner.velocity_enabled = true
  else:
    appearing = false
    
  if appearing:
    owner.position = initial_pos + offset_pos
    
  if custom_script and custom_script.has_method('_process_mixin'):
    custom_script._process_mixin(self, delta)
    
  if on_mario_collide('InsideDetector'):
    if 'set state' in owner.vars:
      if owner.score > 0:
        Global.add_score(owner.score)
        owner.get_parent().add_child(ScoreText.new(owner.score, owner.position))
      if owner.vars['set state'] != Global.state and (not (owner.vars['set state'] == 1 and Global.state > 1) or owner.vars['sgr behavior']):
        Global.Mario.appear_counter = 60
        if Global.state >= 1 or owner.vars['sgr behavior']:
          Global.state = owner.vars['set state']
        else:
          Global.state = 1
        Global.play_base_sound('MAIN_Powerup')
      if !owner.vars['sgr behavior']:
        Global.play_base_sound('MAIN_Powerup')
        if !owner.death_signal_exception: owner.emit_signal('enemy_died')
        owner.queue_free()
    elif 'custom action' in owner.vars:
      var action_class = owner.vars['custom action'].new()
      action_class.do_action(self)
