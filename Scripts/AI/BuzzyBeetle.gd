extends Brain

var is_shell: bool = false
var stopped_shell: bool = false
var shell_counter: float = 0
var score_mp: int
var upside_down_state: int = 0
var on_freeze: bool = false
var shell_speed: float = 0

var kill_exceptions: Array

func _ready_mixin():
	owner.death_type = AliveObject.DEATH_TYPE.NONE
	if owner.vars['is shell']:
# warning-ignore:standalone_ternary
		to_stopped_shell() if owner.vars['stopped'] else to_moving_shell()
	
	yield(owner.get_tree(), 'idle_frame')
	for n in kill_exceptions:
		var inst = instance_from_id(n)
		owner.add_collision_exception_with(inst)
		
func _setup(b)-> void:
	._setup(b)
	
	# Upside-down behaviour
	if owner.vars['upside down']:
		owner.animated_sprite.flip_v = true
		owner.gravity_scale = 0 - owner.gravity_scale

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	
	if !owner.is_on_floor():
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
	
	if !owner.alive:
		owner.get_node('KillZone').get_child(0).disabled = true
		owner.get_node('QBlockZone').get_child(0).disabled = true
		owner.animated_sprite.flip_v = false
		return
	
	if !owner.frozen:
# warning-ignore:incompatible_ternary
		owner.velocity.x = (owner.vars['speed'] if !is_shell else 0 if stopped_shell else shell_speed) * owner.dir
	else:
#		if !on_freeze:
#			on_freeze = true
#			owner.animated_sprite.position.y = 2
#			owner.velocity.x = 0
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
		owner.gravity_scale = 1
		return
	
	var turn_if_no_break: bool = true
		
	for b in owner.get_node('KillZone').get_overlapping_bodies():
		if is_shell && !stopped_shell && abs(owner.velocity.x) > 0:
			if b.is_class('KinematicBody2D') && b != owner && b.has_method('kill'):
				if b.get_instance_id() in kill_exceptions:
					return
				var brain = b.get_node_or_null('Brain')
				if is_instance_valid(brain) and 'stopped_shell' in brain and !brain.stopped_shell and 'is_shell' in brain and brain.is_shell and !b.frozen:
					owner.kill(AliveObject.DEATH_TYPE.FALL if !owner.force_death_type else owner.death_type, 0, null, null, true)
					b.kill(AliveObject.DEATH_TYPE.FALL if !b.force_death_type else b.death_type, 0, null, self.name)
					return
				if b.invincible: return
				b.kill(AliveObject.DEATH_TYPE.FALL if !b.force_death_type else b.death_type, score_mp, null, self.name)
				if score_mp < 6:
					score_mp += 1
				else:
					score_mp = 0
					
	for b in owner.get_node('QBlockZone').get_overlapping_bodies():
		if is_shell && !stopped_shell && abs(owner.velocity.x) > 0:
			if b.has_method('hit'):
				b.hit(true)
				owner.turn()
				turn_if_no_break = false
	
	if owner.is_on_wall() and turn_if_no_break:
		owner.turn()
		if is_shell:
			owner.animated_sprite.flip_h = false
	
	# Upside-down behaviour
	if owner.vars['upside down']:
		if Global.is_mario_collide_area('InsideDetector', owner.get_node('TriggerZone')) and upside_down_state == 0:
#		if (
#			Global.Mario.position.x > owner.position.x - 80 and
#			Global.Mario.position.x < owner.position.x + 80 and
#			Global.Mario.position.y > owner.position.y - 96 and
#			Global.Mario.position.y < owner.position.y + 500 and
#			upside_down_state == 0
#		):
			upside_down_state = 1
			owner.animated_sprite.animation = 'shell stopped'
			owner.vars['speed'] = 0
			owner.gravity_scale = 0 - owner.gravity_scale
			owner.get_node('TriggerZone/CollisionShape2D').set_deferred('disabled', true)
			
		if upside_down_state == 1 and owner.is_on_floor():
			upside_down_state = 2
			owner.dir = 1 if Global.Mario.position.x > owner.position.x else -1
			owner.animated_sprite.speed_scale = 0.75
			owner.get_node('KillZone').get_child(0).disabled = false
			owner.get_node('QBlockZone').get_child(0).disabled = false
			score_mp = 0
			to_moving_shell(false)
			owner.get_node('bump').play()
			owner.get_parent().add_child(Explosion.new(owner.position + Vector2(0, -16)))
		

	if shell_counter < 41:
		shell_counter += 1 * Global.get_delta(delta)
		
	if is_mario_collide('BottomDetector') and Global.Mario.velocity.y >= -1 && shell_counter >= 11 and upside_down_state != 1: 
		if !is_shell:
			owner.get_parent().add_child(ScoreText.new(100, owner.position))
			to_stopped_shell()
		
			owner.sound.play()
			Global.Mario.enemy_stomp()
		elif is_shell && !stopped_shell: #Stops the shell
			owner.get_parent().add_child(ScoreText.new(100, owner.position))
			to_stopped_shell()
			if upside_down_state == 2: upside_down_state = 3
		
			owner.sound.play()
			Global.Mario.enemy_stomp()
	elif is_mario_collide('InsideDetector') and !stopped_shell and shell_counter >= 31:
		Global._ppd()
		
	if is_mario_collide('InsideDetector'):
		if stopped_shell && is_shell && shell_counter >= 11:
			to_moving_shell()
			owner.dir = -1 if Global.Mario.position.x > owner.position.x else 1
			owner.alt_sound.pitch_scale = 0.9
			owner.alt_sound.play()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in range(len(g_overlaps)):
		if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
			owner.kill(AliveObject.DEATH_TYPE.FALL, 0)

func to_stopped_shell() -> void:
	owner.get_node('KillZone').get_child(0).disabled = false
	owner.get_node('QBlockZone').get_child(0).disabled = false
	shell_counter = 0
	is_shell = true
	score_mp = 0
	stopped_shell = true
	owner.animated_sprite.animation = 'shell stopped'
	owner.get_node('VisibilityEnabler2D').rect = Rect2( -16, -32, 32, 32 )
	if !owner.death_signal_exception: owner.emit_signal('enemy_died')
	shell_speed = owner.vars['shell speed']
	kill_exceptions = []

func to_moving_shell(reset_counter: bool = true) -> void:
	owner.get_node('KillZone').get_child(0).disabled = false
	owner.get_node('QBlockZone').get_child(0).disabled = false
	is_shell = true
	stopped_shell = false
	owner.animated_sprite.animation = 'shell moving'
	owner.get_node('VisibilityEnabler2D').rect = Rect2( -480, -192, 960, 320 )
	
	if reset_counter:
		shell_counter = 0
		owner.animated_sprite.speed_scale = 1
	else:
		shell_counter = 40
		shell_speed = owner.vars['upside down shell speed']
