extends StaticBody2D
class_name Cannon, "res://GFX/Editor/Enemy.png"

var on_screen: bool
var counter: float = 0

export var delay: float = 25
export var result: PackedScene = preload('res://Objects/Enemies/Bullet.tscn')
export var custom_sound: Resource
export var bullet_speed: float = 0

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func _physics_process(delta) -> void:
	if (position.x > Global.Mario.position.x + 80 or position.x < Global.Mario.position.x - 80):
		counter += 1 * Global.get_delta(delta)
	
	if counter > delay:
		counter = rand_range(50, 200) * -1
		if custom_sound:
			$Shoot.stream = custom_sound
		else:
			$Shoot.pitch_scale = rng.randf_range(1, 1.2)
		$Shoot.play()
		var bullet = result.instance()
		bullet.dir = -1 if Global.Mario.global_position.rotated(-global_rotation).x < global_position.rotated(-global_rotation).x else 1
		bullet.z_index = 1
		var explosionPos = global_position + Vector2(bullet.dir * 16, 0).rotated(global_rotation)
		var explosion = Explosion.new(explosionPos)
		Global.current_scene.add_child(bullet)
		Global.current_scene.add_child(explosion)
		bullet.global_position = Vector2(global_position.x, global_position.y)
		bullet.global_rotation = global_rotation
		if bullet_speed > 0 and bullet.has_node('Brain') and 'speed' in bullet.get_node('Brain'):
			bullet.get_node('Brain').speed = bullet_speed

func _on_screen_entered() -> void:
	on_screen = true

func _on_screen_exited() -> void:
	on_screen = false
