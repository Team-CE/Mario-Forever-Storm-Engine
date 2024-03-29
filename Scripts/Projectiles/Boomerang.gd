extends Area2D

const mariospr = preload('res://GFX/Enemies/boomermario.png')
const emalpkaspr = preload('res://GFX/Enemies/boomerenemy.png')

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(10, -6)
var flag2: bool = false
var gravity_scale: float = 1

var belongs: int = 0 # 0 - Mario, 1 - Bro, 2 - Spikeball Launcher
var emalpka_owner = null

func _ready() -> void:
	velocity.x *= dir
# warning-ignore:return_value_discarded
	vis.connect('screen_exited', self, '_on_screen_exited')
# warning-ignore:return_value_discarded
	vis.connect('tree_exited', self, '_on_tree_exited')

	add_child(vis)
	
	if belongs == 0:
		$Sprite.texture = mariospr
	else:
		$Sprite.texture = emalpkaspr

func _physics_process(delta) -> void:
	var overlaps = self.get_overlapping_bodies()
	var overlaps_area = self.get_overlapping_areas()

	if overlaps.size() > 0:
		for i in overlaps:
			if belongs == 0:
				if i.is_in_group('Enemy') and i.has_method('kill'):
					var killed = i.kill(AliveObject.DEATH_TYPE.FALL if !i.force_death_type else i.death_type, 0, null, self.name)
					if killed:
						explode()
			elif belongs == 1 and emalpka_owner and flag2:
				if i.has_node('Brain') and i.get_node('Brain').get_instance_id() == emalpka_owner:
					queue_free()
	
	if overlaps_area.size() > 0 and belongs == 0:
		for i in overlaps_area:
			if 'Coin' in i.name:
				i.trigger_fly()
				
	if is_mario_collide('InsideDetector'):
		if belongs != 0:
			Global._ppd()
		elif flag2:
			queue_free()

	if !flag2:
		if velocity.y < 4:
			velocity.y += 0.3 * Global.get_delta(delta)
		else:
			flag2 = true
		
	else:
		if velocity.y > 0:
			velocity.y -= 0.25 * Global.get_delta(delta)
		elif velocity.y < 0:
			velocity.y = 0
	
	if (velocity.x > -10 and dir == 1) or (velocity.x < 10 and dir == -1):
		velocity.x -= 0.2 * dir * Global.get_delta(delta)
	if velocity.x <= 2.0 and velocity.x >= -2.0 and dir == 1:
		velocity.x = -2
	if velocity.x >= -2.0 and velocity.x <= 2.0 and dir == -1:
		velocity.x = 2

	position += velocity.rotated(rotation) * Global.get_delta(delta)
	
	$Sprite.rotation_degrees += 20 * (-1 if $Sprite.flip_h else 1) * Global.get_delta(delta)
	
func is_mario_collide(_detector_name: String) -> bool:
	var collisions = Global.Mario.get_node(_detector_name).get_overlapping_areas()
	return collisions && collisions.has(self)

func explode() -> void:
	var explosion = Explosion.new(position)
	get_parent().add_child(explosion)
	#queue_free()

func _on_screen_exited() -> void:
	if belongs == 2:
		return
	queue_free()
	
func _on_tree_exited() -> void:
	if belongs == 0:
		Global.projectiles_count -= 1

func _on_level_complete() -> int:
	var score = 200
	var score_text = ScoreText.new(score, position)
	get_parent().add_child(score_text)
	queue_free()
	return score
