extends Brain

var on_freeze: bool = false
var counter: float = 0
var counter_t: float = 0
var move_multiplier: int = 1
var throw_activated: bool = false
var inv_counter: float = 0

var jumping_down: bool = false
var exceptions: Array = []

var initial_pos: Vector2
var inited_throwable

var rng: RandomNumberGenerator
var rng2: RandomNumberGenerator

onready var ray1: RayCast2D 
onready var ray2: RayCast2D
onready var ray3: RayCast2D
onready var ray4: RayCast2D

func _ready_mixin() -> void:
	owner.death_type = AliveObject.DEATH_TYPE.FALL
	ray1 = owner.get_node('RayCast2D')
	ray2 = owner.get_node('RayCast2D2')
	ray3 = owner.get_node('RayCast2D3')
	ray4 = owner.get_node('RayCast2D4')
	
func _setup(b) -> void:
	._setup(b)
	initial_pos = owner.position
	inited_throwable = owner.vars['throw_script'].new()
	rng = RandomNumberGenerator.new()
	rng.seed = 1
	rng2 = RandomNumberGenerator.new()
	rng2.randomize()

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
		
	jumping_ai(Global.get_delta(delta))
	
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


func jumping_ai(delta) -> void:
	if ray1 == null or ray2 == null or ray3 == null or ray4 == null:
		return
	
	if not jumping_down:
		if owner.velocity.y > 0:
			clear_exceptions()
		
		if owner.velocity.y < 0:
# warning-ignore:return_value_discarded
			collide_ray(ray1)
# warning-ignore:return_value_discarded
			collide_ray(ray2)
	else:
		var collided_once: bool
		if owner.velocity.y > 0:
			collided_once = collide_ray(ray3) or collide_ray(ray4)
		if owner.velocity.y == 0 and collided_once:
			clear_exceptions()

	if counter < 20:
		counter += 1 * delta
	else:
		counter = 0
# warning-ignore:narrowing_conversion
		move_multiplier = round(rng.randf_range(-4, 14) / 10)
		if owner.is_on_floor() and rng2.randi_range(1, 11) > 10:
			jumping_down = false
			owner.velocity.y = -400
			return
		if owner.is_on_floor() and rng2.randi_range(1, 11) > 10 and (qblock_below(ray3) or qblock_below(ray4)):
			jumping_down = true
			owner.velocity.y = -150

func collide_ray(ray: RayCast2D) -> bool:
	var collider = ray.get_collider()
	if qblock_below(ray):
		if !exceptions.has(collider.get_instance_id()):
			exceptions.append(collider.get_instance_id())
			owner.add_collision_exception_with(collider)
			ray.add_exception(collider)
			return true
	return false

func clear_exceptions() -> void:
	if exceptions.empty(): return
	for body in exceptions:
		owner.remove_collision_exception_with(instance_from_id(body))
	ray1.clear_exceptions()
	ray2.clear_exceptions()
	ray3.clear_exceptions()
	ray4.clear_exceptions()
	exceptions.clear()
	jumping_down = false

func qblock_below(ray: RayCast2D) -> bool:
	if !ray.is_colliding():
		return false
	
	var collider = ray.get_collider()
	if collider is QBlock:
		return true
	return false
