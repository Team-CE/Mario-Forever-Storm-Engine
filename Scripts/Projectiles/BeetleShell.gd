extends KinematicBody2D

var shell_scene = preload('res://Objects/Enemies/Koopas/BuzzyBeetle.tscn')

var belongs: int = 0

var velocity := Vector2(5, -10)
var collision
var parent: int

func _ready():
	pass

func _physics_process(delta):
	collision = move_and_collide(velocity * Global.get_delta(delta))
	if collision and 'collider' in collision:
		if collision.collider.has_method('hit'):
			collision.collider.hit(true, false)
			move_shell(delta)
		else:
			move_shell(delta)
	
	var overlaps = $CollisionArea.get_overlapping_bodies()

	if overlaps.size() > 0 and belongs == 0:
		for i in overlaps:
			if i.is_in_group('Enemy') and i.has_method('kill'):
				i.kill(AliveObject.DEATH_TYPE.FALL if !i.force_death_type else i.death_type, 0, null, self.name)
				
	if belongs != 0:
		if Global.is_mario_collide('BottomDetector', self) and Global.Mario.velocity.y >= -1:
			stop_shell(delta)
			Global.current_scene.add_child(ScoreText.new(100, global_position))
			Global.play_base_sound('ENEMY_Stomp')
			Global.Mario.enemy_stomp()
		elif Global.is_mario_collide('InsideDetector', self):
			Global._ppd()
	
	velocity.y += 0.33 * Global.get_delta(delta)
	$AnimatedSprite.rotation_degrees += 13 * Global.get_delta(delta)

func move_shell(delta) -> void:
	var shell = shell_scene.instance()
	shell.global_position = global_position
	get_parent().add_child(shell)
	shell.vars = shell.vars.duplicate(false)
	shell.get_node('Brain').to_moving_shell(false)
	shell.animated_sprite.speed_scale = 0.8
	shell.get_node('Brain').kill_exceptions.append(parent)
	shell.position.y += 15 * Global.get_delta(delta)
	if Global.Mario.position.x > shell.position.x:
		shell.dir *= -1
	
	var explosion = Explosion.new(position)
	get_parent().add_child(explosion)
	
	call_deferred('queue_free')

func stop_shell(delta) -> void:
	var shell = shell_scene.instance()
	shell.global_position = global_position
	get_parent().add_child(shell)
	shell.vars = shell.vars.duplicate(false)
	shell.get_node('Brain').to_stopped_shell()
	shell.position.y += 15 * Global.get_delta(delta)
	
	call_deferred('queue_free')
