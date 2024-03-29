extends Brain

var initial_pos: Vector2
var offset_pos: Vector2 = Vector2.ZERO

var shell_counter: float = 0
var counter: float = 0

func _ready_mixin():
	initial_pos = owner.position
	owner.velocity_enabled = false

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	
	if owner.frozen:
		owner.get_node('Collision2').disabled = false
		owner.get_node('Collision').disabled = true
		owner.velocity.x = lerp(owner.velocity.x, 0, 0.05 * Global.get_delta(delta))
	
	if !owner.alive or owner.frozen:
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
		owner.velocity_enabled = true
		return
	
	if shell_counter < 11:
		shell_counter += 1 * Global.get_delta(delta)
		
	owner.animated_sprite.flip_h = owner.position.x > Global.Mario.position.x
	
	counter += (float(owner.vars['fly speed']) / 45.0) * Global.get_delta(delta)
	offset_pos = Vector2(owner.vars['fly radius'] * sin(counter), 0)
	
	owner.position = initial_pos + offset_pos
		
	if is_mario_collide('BottomDetector') && shell_counter >= 8:
		owner.kill(AliveObject.DEATH_TYPE.CUSTOM, 0)
		Global.Mario.enemy_stomp()
	elif on_mario_collide('InsideDetector') && shell_counter >= 11 && !is_mario_collide('BottomDetector'):
		Global._ppd()
		
	var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
	for i in range(len(g_overlaps)):
		if 'triggered' in g_overlaps[i] and g_overlaps[i].triggered:
			owner.kill(AliveObject.DEATH_TYPE.FALL, 0)

func _on_custom_death(_score_mp):
	owner.sound.play()
	owner.get_parent().add_child(ScoreText.new(owner.score, owner.position))
	# DO NOT use preload to avoid sharing 'vars' dictionary between different instances
	var koopa = preload('res://Objects/Enemies/Koopas/Koopa Red.tscn').instance()
	koopa.position = owner.position
	owner.get_parent().add_child(koopa)
	owner.velocity_enabled = false
	owner.visible = false
	yield(get_tree().create_timer(0.5, false), 'timeout')
	owner.queue_free()
