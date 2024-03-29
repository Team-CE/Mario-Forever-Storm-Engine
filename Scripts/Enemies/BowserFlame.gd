extends Area2D

var target_pos_y: float
var velocity: Vector2
var inv_counter: float = 8
var active: bool = true

onready var rng = RandomNumberGenerator.new()
var rand_y: int

func _ready():
	rng.randomize()
	if !rand_y:
		rand_y = rng.randi_range(-1, 1)
	if !target_pos_y:
		target_pos_y = position.y
	if !velocity:
		velocity.x = 4

func _physics_process(delta):
	if !active: return
	
	position += velocity.rotated(rotation) * Global.get_delta(delta)
	$AnimatedSprite.flip_h = velocity.x < 0
	
	if inv_counter < 7:
		inv_counter += Global.get_delta(delta)

	if rotation_degrees != 0: return

	if position.y > target_pos_y + (rand_y * 32):
		position.y -= 4 * Global.get_delta(delta)
	elif position.y < target_pos_y + (rand_y * 32):
		position.y += 4 * Global.get_delta(delta)
	# Correcting the position because fuck my life
	if (
		position.y > target_pos_y + (rand_y * 32) - 3 and
		position.y < target_pos_y + (rand_y * 32) + 3
		):
			position.y = target_pos_y + (rand_y * 32)

func kill(_a = false, _b = false, _c = false, _d = false, _e = false):
	return

func freeze() -> void:
	# Lava particles
	var lavap = preload('res://Objects/Effects/LavaParticles.tscn').instance()
	lavap.preprocess = 0
	get_parent().add_child(lavap)
	lavap.global_position = global_position
	lavap.process_material.emission_box_extents = Vector3(8, 12, 0)
	var time = Timer.new()
	time.autostart = true
	time.wait_time = 0.3
	time.connect('timeout', lavap, 'set', ['emitting', false])
	time.one_shot = true
	lavap.add_child(time)
	hide()
	set_deferred('collision_layer', 0)
	set_deferred('collision_mask', 0)
	
# warning-ignore:return_value_discarded
	get_tree().create_timer(3.0, false).connect('timeout', self, 'queue_free')
	
	var score = ScoreText.new(200, global_position)
	get_parent().add_child(score)
	$ice1.play()
	active = false

func _on_area_entered(area):
	if !active: return
	if Global.shoe_type > 0 and area.name == 'BottomDetector':
		Global.Mario.shoe_node.stomp()
		inv_counter = 0
		return
	if area.is_in_group('Mario') and inv_counter >= 8:
		Global._ppd()
		return
	if area.is_in_group('Projectile') and area.has_method('bounce') and area.belongs == 0 and area.bounce_count < 3:
		area.bounce()
		area.skip_frame = true
		area.get_node('Bounce').play()
		return
	
	var root: Node2D = area.owner if 'owner' in area else null
	if root == null: return
	
	if 'Iceball'.to_lower() in root.get_name().to_lower():
		freeze()
		root.explode()

func _on_body_entered(body):
	if !active: return
	if body.is_in_group('Projectile') and body.has_method('explode') and body.belongs == 0:
		body.explode()


func _on_VisibilityNotifier2D_screen_exited():
	call_deferred('queue_free')
