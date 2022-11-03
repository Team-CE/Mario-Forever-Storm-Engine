extends Area2D

enum TYPES {
	NORMAL,
	FIRE,
	ICE
}

export(TYPES) var type: int = 0
export var shoot_interval: float = 10.0
export var shoot_wait_delay: float = 150
export var projectile_count: int = 3

var shooting: bool = false
var projectile_counter: int = 0
var projectile_timer: float = 0
var fireball
onready var wait_timer: float = shoot_wait_delay

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	
	if type == TYPES.FIRE:
		$AnimatedSprite.animation = 'fire'
	elif type == TYPES.ICE:
		$AnimatedSprite.animation = 'ice'

func _physics_process(delta):
	if type > 0:
		_process_shooting(delta)
	
		if projectile_timer > 0:
			projectile_timer -= 1 * Global.get_delta(delta)
		
		if wait_timer > shoot_wait_delay:
			shooting = true
			wait_timer = 0
		
		wait_timer += 1 * Global.get_delta(delta)

func _on_area_entered(area):
	if area.name == 'InsideDetector':
		Global._ppd()

func killpiranha():
	var explosion = Explosion.new(position - Vector2(0, 16))
	get_parent().add_child(explosion)
	queue_free()

func _process_shooting(_delta):
	if projectile_timer <= 0 and projectile_counter < projectile_count and shooting:
		$Shoot.play()
		projectile_timer = shoot_interval
		projectile_counter += 1
		if type == TYPES.ICE:
			fireball = preload('res://Objects/Projectiles/Iceball.tscn').instance()
		else:
			fireball = preload('res://Objects/Projectiles/Fireball.tscn').instance()
		fireball.velocity = Vector2(rng.randf_range(-200.0, 200.0), rng.randf_range(-70, -600)).rotated(rotation)
		fireball.position = position + Vector2(0, -16).rotated(rotation)
		fireball.belongs = 1
		fireball.gravity_scale = 0.5
		fireball.z_index = 1
		get_parent().add_child(fireball)
	
	if projectile_counter >= projectile_count:
		shooting = false
		projectile_counter = 0
		projectile_timer = 0
