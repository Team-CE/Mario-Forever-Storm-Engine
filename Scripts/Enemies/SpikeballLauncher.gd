extends Node2D

export var motion_launch_add: Vector2

const popcorn_scene = preload('res://Objects/Projectiles/Chainsaw.tscn')
var timer_delay: float = 100
var launch_timer: float
var velocity: Vector2

onready var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func _physics_process(delta):
	if not Global.is_getting_closer(-16, global_position):
		return
	timer_delay += Global.get_delta(delta)
	if timer_delay > 150:
		timer_delay = 0
		$Fire.play()
		
		var popcorn = popcorn_scene.instance()
		popcorn.belongs = 2
		velocity.x = rng.randi_range(-2, 2)
		var vel_y_correction = cos(rotation) / 2 + 0.5
		velocity.y = (-5 * vel_y_correction) - rng.randf_range(0, 3)
		popcorn.velocity = (velocity.rotated(rotation) + motion_launch_add.rotated(rotation)) * 50
		Global.current_scene.add_child(popcorn)
		popcorn.global_transform = global_transform
		
		var explosion = Explosion.new(position)
		Global.current_scene.add_child(explosion)
		explosion.z_index = 2
		
