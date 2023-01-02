extends Brain

var c_wake: float = 0
var c_wake_bool: bool

func _ready_mixin():
	owner.death_type = AliveObject.DEATH_TYPE.CUSTOM

func _setup(b) -> void:
	._setup(b)

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	
	if !owner.is_on_floor():
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
	
	if !owner.alive:
		crushed(delta)
		return
	
	owner.velocity.x = owner.vars['speed'] * owner.dir
	
	if owner.is_on_wall():
		owner.turn()
	
	if is_mario_collide('BottomDetector') and Global.Mario.velocity.y >= -1: 
		owner.kill(AliveObject.DEATH_TYPE.CUSTOM)
	
		Global.Mario.enemy_stomp()
	elif is_mario_collide('InsideDetector'):
		Global._ppd()

func _on_custom_death(score_mp = 1) -> void:
	owner.sound.play()
	owner.get_parent().add_child(ScoreText.new(owner.score * owner.multiplier_scores[score_mp], owner.position))
	owner.animated_sprite.set_animation('crash')
	owner.animated_sprite.frame = 0
	owner.alive = false
	owner.velocity.x = 0
	owner.collision_layer = 0
	owner.collision_mask = 0b10

func crushed(delta) -> void:
	owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
	
	c_wake += 1 * Global.get_delta(delta)
	if c_wake > 150 and c_wake < 230:
		owner.animated_sprite.offset.x = cos(c_wake)
	if c_wake > 230 and !c_wake_bool:
		owner.animated_sprite.set_animation('uncrash')
		owner.animated_sprite.offset.x = 0
		c_wake_bool = true
	if c_wake > 250:
		c_wake = 0
    c_wake_bool = false
		owner.alive = true
		owner.animated_sprite.set_animation('default')
		owner.gravity_scale = 1
		owner.collision_layer = 1
		owner.collision_mask = 0b11
		if Global.Mario.position.x > owner.position.x:
			owner.turn()
		
