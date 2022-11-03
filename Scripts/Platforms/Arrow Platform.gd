extends StaticBody2D

var plat = preload('res://Objects/Platforms/ArrowMovingPlatform.tscn')

enum DIRECTION {
	UP,
	LEFT,
	RIGHT,
	UNIVERSAL
 }

export(DIRECTION) var dir: int
export var speed: float = 1
export var life_time: float = 608
var vector_dir: Vector2

var colliding: bool = false

func _ready():
	$Body.animation = str(dir)
	match dir:
		1:
			vector_dir = Vector2.LEFT
		2:
			vector_dir = Vector2.RIGHT
		_:
			vector_dir = Vector2.UP
	
func _physics_process(_delta):
	var isCol: bool = Global.is_mario_collide('BottomDetector', self) and Global.Mario.is_on_floor()
	if !colliding && isCol:
		colliding = true
		create_platform()
		return
	elif colliding && !isCol:
		colliding = false

func create_platform():
	for i in get_tree().get_nodes_in_group('ArrowMovingPlatform'):
		i.queue_free()
	var moving_platform = plat.instance()
	add_child(moving_platform)
	moving_platform.vector_dir = vector_dir
	moving_platform.speed = speed
	moving_platform.life_time = life_time
	moving_platform.timer = 0
	moving_platform.position += Vector2(0, -0.1) + vector_dir.rotated(rotation)
	moving_platform.get_node('Body').animation = $Body.animation
#	return true
#Global.current_scene.get_node('../ArrowMovingPlatform')
