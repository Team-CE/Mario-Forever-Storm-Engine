extends KinematicBody2D

enum TYPES {
	NONE
	RED
	GREEN
}
export(TYPES) var type = TYPES.GREEN

var is_free: bool = true
var dead: bool = false
var velocity := Vector2.ZERO

func _ready():
	pass

func _physics_process(delta):
	if dead:
		position += velocity.rotated(rotation) * Global.get_delta(delta)
		velocity += Vector2(0, 0.4).rotated(rotation) * Global.get_delta(delta)
		return
	if is_free:
		if !Global.Mario.is_in_shoe and Global.is_mario_collide('BottomDetector', self):
			get_inside()
			return
		velocity = move_and_slide(velocity.rotated(rotation), Vector2.UP.rotated(rotation))
		velocity.x = 0
		if !is_on_floor():
			velocity.y += 25 * Global.get_delta(delta)
	else:
		$AnimatedSprite.global_transform = Global.Mario.get_node('Sprite').global_transform
		$AnimatedSprite.flip_h = Global.Mario.get_node('Sprite').flip_h
		if Global.state == 0:
			$AnimatedSprite.global_position.y = Global.Mario.get_node('Sprite').global_position.y + 16

func get_inside():
	is_free = false
	Global.Mario.bind_shoe(get_instance_id())
	Global.play_base_sound('ENEMY_Stomp')
	#Global.Mario.get_node('AnimationPlayer').play('Small' if Global.state == 0 else 'Big')
	#z_index = 11

func shoe_hit():
	dead = true
	velocity = Vector2(2 if $AnimatedSprite.flip_h else -2, -8).rotated(rotation)
	$AnimatedSprite.flip_v = true

func stomp():
	$stomp.play()
	Global.Mario.enemy_stomp()
	var explosion = preload('res://Scripts/Effects/StompEffect.gd').new(Global.Mario.position)
	get_parent().add_child(explosion)
