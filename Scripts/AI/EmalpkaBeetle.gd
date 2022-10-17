extends Brain

var on_freeze: bool = false
var counter: float = 0
var counter_t: float = 0
var move_multiplier: int = 1
var throw_activated: bool = false
var inv_counter: float = 0

var initial_pos: Vector2
var inited_throwable

var hide_timer: float = 0
var beetle_scene: PackedScene = preload('res://Objects/Enemies/Koopas/BuzzyBeetle.tscn')

var rng: RandomNumberGenerator

func _ready_mixin() -> void:
	owner.death_type = AliveObject.DEATH_TYPE.FALL
	
func _setup(b) -> void:
	._setup(b)
	initial_pos = owner.position
	inited_throwable = owner.vars['throw_script'].new()
	rng = RandomNumberGenerator.new()
	rng.seed = 1

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	if !owner.is_on_floor():
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
	
	if owner.frozen:
		owner.get_node('CollisionShape2D').disabled = true
		if !on_freeze:
			on_freeze = true
			if 'holding' in owner.animated_sprite.animation:
				owner.animated_sprite.animation = 'walk'
			elif owner.animated_sprite.animation == 'hide' and owner.animated_sprite.frame == 1:
				owner.get_node('Collision3').disabled = false
				owner.frozen_sprite.animation = 'small'
				owner.frozen_sprite.position.y = -16
				return
			
			owner.get_node('Collision2').disabled = false
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
		return
	
	if !owner.alive:
		return
		
	owner.velocity.x = owner.vars["speed"] * owner.dir * move_multiplier
	owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
	
	if inv_counter < 31:
		inv_counter += 1 * Global.get_delta(delta)
		
	if counter < 20:
		counter += 1 * Global.get_delta(delta)
	else:
		counter = 0
# warning-ignore:narrowing_conversion
		if hide_timer == 0:
			move_multiplier = round(rng.randf_range(-4, 14) / 10)
		if rand_range(1, 11) > 10 and owner.is_on_floor():
			owner.velocity.y = -400
		if hide_timer == 0 and not throw_activated and rand_range(1, 10) > 9:
			hide()
	
	if counter_t < 30:
		counter_t += 1 * Global.get_delta(delta)
	else:
		counter_t = 0
		var throw_was_activated: bool = false
			
		if throw_activated:
			owner.animated_sprite.animation = 'walk'
			owner.get_node('Throw').play()
			throw_was_activated = true
			throw_activated = false
			inited_throwable.throw(self)
			
		if hide_timer == 0 and rand_range(1, 18) > 9 and !throw_was_activated:
			throw_activated = true
			owner.animated_sprite.animation = 'holding shell' if owner.vars['shell_launch'] else 'holding'
	
	# Hiding from fireballs
	beetle_logic()
	
	if hide_timer > 0.1:
		hide_timer += 1 * Global.get_delta(delta)
		if hide_timer > 40:
			owner.animated_sprite.animation = 'show'
		if hide_timer > 50:
			hide_timer = 0
			owner.animated_sprite.play('walk')
	
	if (initial_pos - owner.position).x > 70:
		owner.dir = -1
		owner.velocity.x = owner.vars["speed"] * owner.dir
	elif (initial_pos - owner.position).x < -70:
		owner.dir = 1
		owner.velocity.x = owner.vars["speed"] * owner.dir
	
	owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
	
	if is_mario_collide('BottomDetector') and Global.Mario.velocity.y >= -1 && inv_counter >= 11:
		var beetle = beetle_scene.instance()
		owner.get_parent().add_child(beetle)
		beetle.vars = beetle.vars.duplicate(false)
		beetle.get_node('Brain').to_stopped_shell()
		beetle.global_position = owner.global_position
		if Input.is_action_pressed('mario_jump'):
			Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
		else:
			Global.Mario.velocity.y = -owner.vars["bounce"] * 50
		owner.kill(AliveObject.DEATH_TYPE.BASIC, 0, owner.sound)
	elif on_mario_collide('InsideDetector') && inv_counter >= 21:
		Global._ppd()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in range(len(g_overlaps)):
		if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
			owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
	
func hide() -> void:
	hide_timer = 1
	owner.animated_sprite.play('hide')
	move_multiplier = 0

func beetle_logic() -> void:
	for i in get_tree().get_nodes_in_group('Projectile'):
		if ('Fireball' in i.name or 'Iceball' in i.name) and i.belongs == 0:
			if i.global_position.x > owner.global_position.x - 128 and i.global_position.x < owner.global_position.x + 128:
				throw_activated = false
				if hide_timer == 0 or hide_timer > 40:
					hide()
				hide_timer = 1
