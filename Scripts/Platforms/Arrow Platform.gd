extends StaticBody2D

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
	
func _process(delta):
	var isCol: bool = Global.is_mario_collide('BottomDetector', self)
	if !colliding && isCol:
		colliding = true
		create_platform(delta)
		return
	elif colliding && !isCol:
		colliding = false

func create_platform(_delta):
	if is_instance_valid(get_node_or_null('../ArrowMovingPlatform')):
		get_node('../ArrowMovingPlatform').free()
	var moving_platform = preload('res://Objects/Platforms/ArrowMovingPlatform.tscn').instance()
	moving_platform.set_name('ArrowMovingPlatform')
	get_parent().add_child(moving_platform)
	get_node('../ArrowMovingPlatform').position = position - Vector2(0, 0.1) + vector_dir.rotated(rotation)
	get_node('../ArrowMovingPlatform').vector_dir = vector_dir
	get_node('../ArrowMovingPlatform').speed = speed
	get_node('../ArrowMovingPlatform').life_time = life_time
	get_node('../ArrowMovingPlatform').timer = 0
	get_node('../ArrowMovingPlatform/Body').animation = $Body.animation
	return true
