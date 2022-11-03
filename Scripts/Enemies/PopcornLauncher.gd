extends StaticBody2D

export var motion_launch: Vector2 = Vector2(-6, 0)

const popcorn_scene = preload('res://Objects/Enemies/Popcorn.tscn')
var timer_delay: float = 200
var left_to_launch: int
var launch_timer: float

func _ready():
	pass

func _physics_process(delta):
	if not Global.is_getting_closer(-16, global_position):
		return
	timer_delay += Global.get_delta(delta)
	if timer_delay > 200:
		timer_delay = 0
		left_to_launch = 16
		$Fire.play()
	if left_to_launch > 0:
		launch_timer += 1 * Global.get_delta(delta)
		if launch_timer > 3:
			launch_timer = 0
			left_to_launch -= 1
			var popcorn = popcorn_scene.instance()
			popcorn.velocity = motion_launch
			Global.current_scene.add_child(popcorn)
			popcorn.global_transform = global_transform
		
