extends StaticBody2D

enum DIRECTION {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

var on_screen: bool
var counter: float = 0

export var delay: float = 25
export var result: PackedScene = preload('res://Objects/Enemies/Bullet.tscn')
export var custom_sound: Resource
export(DIRECTION) var dir: float = DIRECTION.LEFT

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func _physics_process(delta) -> void:
	if ((dir == DIRECTION.LEFT and position.x > Global.Mario.position.x + 80)
		or (dir == DIRECTION.RIGHT and position.x < Global.Mario.position.x - 80)):
		counter += 1 * Global.get_delta(delta)
	elif (
			((dir == DIRECTION.UP and position.y > Global.Mario.position.y) or
			(dir == DIRECTION.DOWN and position.y < Global.Mario.position.y)) and
			(position.x > Global.Mario.position.x + 80 or position.x < Global.Mario.position.x - 80)
		):
		counter += 1 * Global.get_delta(delta)
	
	if counter > delay:
		counter = rand_range(50, 200) * -1
		if custom_sound:
			$Shoot.stream = custom_sound
			$Shoot.volume_db = 0
		else:
			$Shoot.pitch_scale = rng.randf_range(1, 1.2)
		$Shoot.play()
		var bullet = result.instance()
		bullet.position = Vector2(position.x, position.y)
		bullet.dir = -1 if Global.Mario.position.rotated(-rotation).x < position.rotated(-rotation).x else 1
		bullet.rotation = rotation
		bullet.z_index = 1
		var explosionPos = position + Vector2(bullet.dir * 16, 0).rotated(rotation)
		var explosion = Explosion.new(explosionPos)
		get_parent().add_child(bullet)
		get_parent().add_child(explosion)

func _on_screen_entered() -> void:
	on_screen = true

func _on_screen_exited() -> void:
	on_screen = false
