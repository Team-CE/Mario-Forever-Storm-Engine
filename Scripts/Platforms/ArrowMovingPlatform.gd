extends KinematicBody2D

var timer: float = 0

var vector_dir: Vector2
var speed: float
var life_time: float

func _ready():
	for i in Global.current_scene.get_children():
		if i is AliveObject and 'Thwomp' in i.name:
			add_collision_exception_with(i)

func _physics_process(delta):
	timer += speed * Global.get_delta(delta)
	position += vector_dir.rotated(rotation) * Vector2(speed, speed) * Global.get_delta(delta)
	if timer > life_time / 1.267:
		$Body.visible = int(timer) % 2 == 0
	if timer > life_time:
		queue_free()
	
	if vector_dir == Vector2.UP:
		var colliding = false
		for i in Global.Mario.get_node_or_null('TopDetector').get_overlapping_bodies():
			if i is TileMap:
				colliding = true
		if colliding and Global.is_mario_collide('BottomDetector', self):
			queue_free()
	elif vector_dir == Vector2.LEFT or vector_dir == Vector2.RIGHT:
		var colliding = false
		for i in Global.Mario.get_node_or_null('SmallLeftDetector').get_overlapping_bodies():
			if i is TileMap:
				colliding = true
		
		for i in Global.Mario.get_node_or_null('SmallRightDetector').get_overlapping_bodies():
			if i is TileMap:
				colliding = true
		if colliding and (Global.is_mario_collide('SmallLeftDetector', self) or Global.is_mario_collide('SmallRightDetector', self)):
			queue_free()
