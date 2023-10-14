extends Brain

var is_shell: bool = false
var stopped_shell: bool = false
var on_freeze: bool = false
var shell_counter: float = 0
var score_mp: int
var ooawel: bool = false

func _ready_mixin():
	owner.death_type = AliveObject.DEATH_TYPE.NONE
	if owner.vars['is shell']:
# warning-ignore:standalone_ternary
		to_stopped_shell() if owner.vars['stopped'] else to_moving_shell()
		
func _setup(b)-> void:
	._setup(b)

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	
	if !owner.is_on_floor():
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
	
	if !owner.alive:
		owner.get_node('KillZone').get_child(0).disabled = true
		owner.get_node('QBlockZone').get_child(0).disabled = true
		return
	
	if !owner.frozen:
		owner.velocity.x = (owner.vars['speed'] if !is_shell else 0 if stopped_shell else owner.vars['shell speed']) * owner.dir
	else:
#		if !on_freeze:
#			on_freeze = true
#			owner.velocity.x = 0
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
		if !is_shell:
			owner.get_node('Collision2').disabled = false
			owner.get_node('Collision').disabled = true
			owner.frozen_sprite.animation = 'medium'
			owner.frozen_sprite.offset.y = -32
			if !ooawel:
				owner.set_clipper_position(Vector2(0, -32))
				ooawel = true
		return
	
	var turn_if_no_break: bool = true
		
	for b in owner.get_node('KillZone').get_overlapping_bodies():
		if is_shell && !stopped_shell && abs(owner.velocity.x) > 0:
			if b.is_class('KinematicBody2D') && b != owner && b.has_method('kill'): #&& Global.is_getting_closer(-32, owner.position):
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
			if b is QBlock and b.active:
				b.hit(true)
				owner.turn()
				turn_if_no_break = false
	
	if owner.is_on_wall() and turn_if_no_break:
		owner.turn()
		if is_shell:
			owner.animated_sprite.flip_h = false
	
	if shell_counter < 41:
		shell_counter += 1 * Global.get_delta(delta)
	
	if is_mario_collide('InsideDetector') && !is_mario_collide('BottomDetector') \
	and !stopped_shell and shell_counter >= 31:
		Global._ppd()
		return
	elif is_mario_collide('BottomDetector') && shell_counter >= 11 && !stopped_shell:
		to_stopped_shell()
		owner.velocity.x = 0
		owner.get_parent().add_child(ScoreText.new(100, owner.position))
	
		owner.sound.play()
		Global.Mario.enemy_stomp()
		return
		
	if is_mario_collide('InsideDetector'):
		if stopped_shell && is_shell && shell_counter >= 11:
			to_moving_shell()
			owner.dir = -1 if Global.Mario.position.x > owner.position.x else 1
			owner.alt_sound.pitch_scale = 0.9
			owner.alt_sound.play()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in g_overlaps:
		if 'triggered' in i and i.triggered:
			owner.kill(AliveObject.DEATH_TYPE.FALL, 0)

func to_stopped_shell() -> void:
	owner.get_node('KillZone').get_child(0).disabled = false
	owner.get_node('QBlockZone').get_child(0).disabled = false
	shell_counter = 0
	is_shell = true
	score_mp = 0
	stopped_shell = true
	owner.animated_sprite.animation = 'shell stopped'
	if Global.Mario.is_in_shoe:
		Global.Mario.shoe_node.stomp()
		owner.kill(AliveObject.DEATH_TYPE.FALL, 0, owner.sound)
		owner.velocity.y = 0
		return
	owner.get_node('VisibilityEnabler2D').rect = Rect2( -16, -32, 32, 32 )
	if !owner.death_signal_exception: owner.emit_signal('enemy_died')

func to_moving_shell() -> void:
	is_shell = true
	stopped_shell = false
	owner.animated_sprite.animation = 'shell moving'
	owner.get_node('VisibilityEnabler2D').rect = Rect2( -480, -192, 960, 320 )
	shell_counter = 0
