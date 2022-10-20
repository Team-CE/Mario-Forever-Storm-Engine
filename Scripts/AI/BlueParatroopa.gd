extends Brain

var on_freeze: bool = false

func _ready_mixin():
	owner.death_type = owner.DEATH_TYPE.FALL

func _setup(b)-> void:
	._setup(b)
# warning-ignore:return_value_discarded
	owner.get_node('KillZone').connect('body_entered',self,"_on_kill_zone_enter")

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	
	if !owner.is_on_floor():
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
		
	if owner.frozen:
#		if !on_freeze:
#			on_freeze = true
#			owner.velocity.x = 0
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
		owner.get_node('Collision2').disabled = false
		owner.get_node('Collision').disabled = true
		return
		
	if !owner.alive:
		return
	
	if owner.is_on_floor():
		owner.velocity.y = -owner.vars['jump_strength']
	
	owner.velocity.x = owner.vars['speed'] * owner.dir
	
	if owner.is_on_wall() and not owner.is_on_ceiling():
		owner.turn()
		
	if on_mario_collide('BottomDetector') and Global.Mario.velocity.y >= -1: 
		owner.kill(owner.DEATH_TYPE.CUSTOM, 0)
		Global.Mario.enemy_stomp()
	elif is_mario_collide('InsideDetector') && !is_mario_collide('BottomDetector'):
		Global._ppd()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in g_overlaps:
		if 'triggered' in i and i.triggered:
			owner.kill(owner.DEATH_TYPE.FALL, 0)

func _on_custom_death(_score_mp):
	owner.sound.play()
	owner.get_parent().add_child(ScoreText.new(owner.score, owner.position))
	var koopa = preload('res://Objects/Enemies/Koopas/Koopa Blue.tscn').instance()
	koopa.position = owner.position
	owner.get_parent().add_child(koopa)
	owner.velocity_enabled = false
	owner.visible = false
	yield(get_tree().create_timer(0.5), 'timeout')
	owner.queue_free()
