extends Brain

signal on_appearing_ended
signal on_mario_collided

const mush = preload('res://Objects/Bonuses/Powerups/Mushroom.tscn')

var appearing: bool = true
var appear_counter: float = 0

var initial_pos: Vector2
var offset_pos: Vector2 = Vector2.ZERO

var custom_script
var custom_appearing: bool = false

func _ready_mixin():
	owner.death_type = AliveObject.DEATH_TYPE.NONE
	if !('sgr behavior' in owner.vars and owner.vars['sgr behavior']): owner.z_index = -5
	owner.velocity_enabled = false
	if !initial_pos:
		initial_pos = owner.position
	
	# Replacing with mushroom if mario is small and state is provided
	if 'set state' in owner.vars and 'from bonus' in owner.vars and owner.vars['from bonus'] and Global.state == 0 and owner.vars['set state'] > 1:
		var mushroom = mush.instance()
		mushroom.transform = owner.transform
		owner.get_parent().add_child(mushroom)
		owner.queue_free()
		
	if 'custom behavior' in owner.vars:
		custom_script = owner.vars['custom behavior'].new()
	
	if 'custom appearing' in owner.vars:
		custom_appearing = true
	
	var children = owner.get_parent().get_children()
	for node in children:
		if node is KinematicBody2D:
			owner.add_collision_exception_with(node)
	
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
			owner.animated_sprite.flip_h = false
	
	if !custom_appearing and not ('sgr behavior' in owner.vars and owner.vars['sgr behavior']):
		if appearing and appear_counter < 32:
			offset_pos -= Vector2(0, owner.vars['grow speed']).rotated(owner.rotation) * Global.get_delta(delta)
			appear_counter += owner.vars['grow speed'] * Global.get_delta(delta)
		elif appear_counter >= 32 and appear_counter < 100:
			emit_signal('on_appearing_ended', owner)
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
				owner.get_parent().add_child(ScoreText.new(owner.score, owner.position))
			if owner.vars['set state'] != Global.state and (not (owner.vars['set state'] == 1 and Global.state > 1) or owner.vars['sgr behavior']):
				Global.Mario.appear_counter = 60
				if Global.state >= 1 or owner.vars['sgr behavior'] or ('force state' in owner.vars and owner.vars['force state']):
					Global.state = owner.vars['set state']
				else:
					Global.state = 1
				Global.play_base_sound('MAIN_Powerup')
			if !owner.vars['sgr behavior']:
				Global.play_base_sound('MAIN_Powerup')
				if !owner.death_signal_exception: owner.emit_signal('enemy_died')
				owner.queue_free()
			elif 'set lives' in owner.vars:
				Global.lives = owner.vars['set lives']
			emit_signal('on_mario_collided')
			
		elif 'custom action' in owner.vars and appear_counter > 10:
			var action_class = owner.vars['custom action'].new()
			if !owner.death_signal_exception: owner.emit_signal('enemy_died')
			action_class.do_action(self)
