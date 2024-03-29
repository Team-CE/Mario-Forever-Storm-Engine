extends AnimatedSprite
class_name BrickEffect

var y_accel: float = 0
var accel: Vector2
var local_rotation: float

var vis: VisibilityNotifier2D

func _init(pos: Vector2 = Vector2.ZERO, acceleration: Vector2 = Vector2.ZERO, texture: SpriteFrames = preload('res://Prefabs/Blocks/Question Block.tres'), rotat: float = Global.Mario.rotation) -> void:
	frames = texture
	animation = 'debris'
	position = pos
	accel = acceleration
	z_index = 3
	rotation = rotat
	local_rotation = rotat
	vis = VisibilityNotifier2D.new()
	add_child(vis)
# warning-ignore:return_value_discarded
	vis.connect('screen_exited', self, '_on_screen_exited')

	if accel.x < 0:
		position += Vector2(-6, 0).rotated(rotation)
	else:
		position += Vector2(6, 0).rotated(rotation)
	
	yield(Global.get_tree(), 'idle_frame')
	if !vis.is_on_screen():
		queue_free()

func _physics_process(delta) -> void:
	y_accel += 0.4 * Global.get_delta(delta)
	position += Vector2(accel.x, accel.y + y_accel).rotated(local_rotation) * Global.get_delta(delta)
	#position.x += accel.x * Global.get_delta(delta)
	#position.y += (accel.y + y_accel) * Global.get_delta(delta)

	if accel.x > 0:
		rotation_degrees += 9 * Global.get_delta(delta)
	else:
		flip_h = true
		rotation_degrees -= 9 * Global.get_delta(delta)

func _on_screen_exited():
	queue_free()
