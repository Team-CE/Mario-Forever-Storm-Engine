extends Brain

var counter: float = 0
var counter_throw: float = 0
var fcounter: float = 0
var move_multiplier: int = 1
var throw_activated: bool = false
var offset_pos: Vector2 = Vector2.ZERO

var initial_pos: Vector2

var inited_throwable

func _ready_mixin() -> void:
	owner.death_type = AliveObject.DEATH_TYPE.CUSTOM
	
func _setup(b) -> void:
	._setup(b)
	initial_pos = owner.position
	inited_throwable = owner.vars['throw_script'].new()

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	if !owner.is_on_floor():
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
	
	if owner.frozen:
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))

	if !owner.alive:
		owner.gravity_scale = 0.6
		return

	owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
	
	fcounter += (float(owner.vars['fly speed']) / 45.0) * Global.get_delta(delta)
	offset_pos = Vector2(0, owner.vars['fly radius'] * sin(fcounter))
	
	owner.position = initial_pos + offset_pos
	
	if counter < 20:
		counter += 1 * Global.get_delta(delta)
	else:
		counter = 0
# warning-ignore:narrowing_conversion
		move_multiplier = round(rand_range(-4, 14) / 10)
		if rand_range(1, 14) > 13 and owner.is_on_floor():
			owner.velocity.y = -400
			
	if counter_throw < 30:
		counter_throw += 1 * Global.get_delta(delta)
	else:
		counter_throw = 0
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
		
	owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
	
	if is_mario_collide('BottomDetector') and Global.Mario.velocity.y >= -1:
		owner.kill(AliveObject.DEATH_TYPE.CUSTOM, 0, owner.sound)
		Global.Mario.enemy_stomp()
	elif on_mario_collide('InsideDetector'):
		Global._ppd()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in g_overlaps:
		if 'triggered' in i and i.triggered:
			owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
	
func _on_custom_death(_score_mp):
	owner.sound.play()
	owner.get_parent().add_child(ScoreText.new(owner.score, owner.position))
	var malpka = preload('res://Objects/Enemies/Emalpkas/Emalpka Hammer.tscn').instance()
	malpka.position = owner.position
	owner.get_parent().add_child(malpka)
	owner.velocity_enabled = false
	owner.visible = false
	yield(get_tree().create_timer(0.5), 'timeout')
	owner.queue_free()
