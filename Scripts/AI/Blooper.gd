extends Brain

var approach_counter: float = 0
var approach_final: float = 0
var timer: float = 0
var moving_up: bool = false
var interpolated_position: Vector2
var move_to: Vector2
var limit_top: float = 0

var ooawel: bool
var rng = RandomNumberGenerator.new()

func _ready_mixin() -> void:
	owner.velocity_enabled = false
	owner.death_type = AliveObject.DEATH_TYPE.FALL
	rng.randomize()
	
	yield(owner.get_tree(), 'idle_frame')
	var camera = Global.current_camera
	
	if 'limit_top' in owner.vars:
		limit_top = owner.vars['limit_top']
	elif camera:
		limit_top = camera.limit_top + 96
	
	for node in get_tree().get_nodes_in_group('Enemy'):
		if node is KinematicBody2D:
			owner.add_collision_exception_with(node)

func _ai_process(delta:float) -> void:
	._ai_process(delta)
	var tween = owner.get_node('Tween')
	if owner.frozen or !owner.alive:
		tween.stop_all()
		owner.velocity_enabled = true
		if owner.frozen:
			owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
			owner.get_node('Collision2').disabled = false
			owner.get_node('CollisionShape2D').disabled = true
			if !ooawel:
				owner.set_clipper_position(Vector2(0, -32))
				ooawel = true
		else:
			owner.velocity.x = 0
		if !owner.is_on_floor():
			owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
		return
	#if owner.is_on_wall():
	#	owner.turn()
	
	var calculated_dir = -1
	
	if approach_counter >= 0:
		owner.animated_sprite.frame = 0
	
	if (owner.position.y > Global.Mario.position.y - 48 and owner.position.y > limit_top) and \
	approach_counter == 0:
		moving_up = true
		move_to = owner.position
		interpolated_position = owner.global_position
		approach_final = owner.vars['speed'] * 0.75
		tween.interpolate_property(self, 'interpolated_position',
			interpolated_position, move_to + Vector2(72 * owner.dir, -96), owner.vars['speed'] / 58.8,
			Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		tween.start()
		tween.seek(owner.vars['speed'] * 0.0025)
	
	if timer < 8:
		timer += 1 * Global.get_delta(delta)
	else:
		timer = 0
		calculated_dir = calculate_dir()
		if calculated_dir:
			owner.dir = calculated_dir
	
	if moving_up:
		approach_counter += 1 * Global.get_delta(delta)
		owner.global_position = Vector2(interpolated_position.x, max(interpolated_position.y, limit_top))
		
		if approach_counter > approach_final:
			moving_up = false
			owner.animated_sprite.frame = 1
			approach_counter = -28
			tween.stop_all()
			
	else:
		owner.position.y += 1.35 * Global.get_delta(delta)
		if approach_counter < 0:
			approach_counter += 1 * Global.get_delta(delta)
		elif approach_counter > 0 and approach_counter < 0.99:
			approach_counter = 0
	
	if is_mario_collide('BottomDetector') and owner.vars['can_stomp']:
		owner.kill(AliveObject.DEATH_TYPE.FALL, 0, owner.sound)
		owner.alive = false
		owner.velocity.y = 0
		Global.Mario.enemy_stomp()
		return
	elif on_mario_collide('InsideDetector') and owner.alive:
		Global._ppd()

func calculate_dir() -> int:
	var mposx = Global.Mario.position.x
	if mposx - 256 > owner.position.x:
		return 1
	elif mposx + 256 < owner.position.x:
		return -1
	else:
		var mpos_math = int(abs((mposx - owner.position.x) / 8))
		var random = rng.randi_range(0, mpos_math)
		var result = mposx - owner.position.x if random < 1 else null
		if result and result > 0:
			result = 1
		elif result and result < 0:
			result = -1
		#print('Pos: ' + str(mpos_math) + ', rand: ' + str(random) + ', result: ' + str(result))
		return result

func getInfo() -> String:
	return str(moving_up) + '\nto: ' + str(move_to)
