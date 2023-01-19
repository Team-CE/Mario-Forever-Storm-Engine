extends Brain

var on_freeze: bool = false
var counter: float = 0
var counter_t: float = 0
var move_multiplier: int = 1
var throw_activated: bool = false
var inv_counter: float = 0

var initial_pos: Vector2
var inited_throwable

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
		owner.get_node('Collision2').disabled = false
		owner.get_node('CollisionShape2D').disabled = true
		if owner.animated_sprite.animation == 'holding':
			owner.animated_sprite.animation = 'walk'
#		if !on_freeze:
#			on_freeze = true
#			owner.velocity.x = 0
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
		return
	
	if !owner.alive:
		return
		
	owner.velocity.x = owner.vars["speed"] * owner.dir * move_multiplier
	owner.animated_sprite.flip_h = owner.global_position.x > Global.Mario.position.x
	
	if inv_counter < 31:
		inv_counter += 1 * Global.get_delta(delta)
		
	if counter < 20:
		counter += 1 * Global.get_delta(delta)
	else:
		counter = 0
# warning-ignore:narrowing_conversion
		move_multiplier = round(rng.randf_range(-4, 14) / 10)
		if rand_range(1, 11) > 10 and owner.is_on_floor():
			owner.velocity.y = -400
	
	if counter_t < owner.vars['throw_delay']:
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
			
		if rand_range(1, 18) > 9 and !throw_was_activated:
			throw_activated = true
			owner.animated_sprite.animation = 'holding'
			
	if (initial_pos - owner.position).x > 70:
		owner.dir = 1
		owner.velocity.x = owner.vars["speed"] * owner.dir
	elif (initial_pos - owner.position).x < -70:
		owner.dir = -1
		owner.velocity.x = owner.vars["speed"] * owner.dir
		
	owner.animated_sprite.flip_h = owner.global_position.x > Global.Mario.position.x
	
	if is_mario_collide('BottomDetector') and Global.Mario.velocity.y >= -1 && inv_counter >= 11:
		owner.kill(AliveObject.DEATH_TYPE.FALL, 0, owner.sound)
		owner.velocity = Vector2.ZERO
		Global.Mario.enemy_stomp()
	elif on_mario_collide('InsideDetector') && inv_counter >= 21:
		Global._ppd()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in range(len(g_overlaps)):
		if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
			owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
	
	
