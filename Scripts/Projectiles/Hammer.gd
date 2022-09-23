extends Node2D

var vis: VisibilityNotifier2D = VisibilityNotifier2D.new()

var dir: int = 1
var velocity: Vector2 = Vector2(5, -10)
var gravity_scale: float = 1

var belongs: int = 0 # 0 - Mario, 1 - Bro

func _ready() -> void:
	velocity.x *= dir
# warning-ignore:return_value_discarded
	vis.connect('screen_exited', self, '_on_screen_exited')
# warning-ignore:return_value_discarded
	vis.connect('tree_exited', self, '_on_tree_exited')

	add_child(vis)
	
	yield(get_tree(), 'idle_frame')
	if !vis.is_on_screen():
		queue_free()

func _process(delta) -> void:
	var overlaps = $CollisionArea.get_overlapping_bodies()

	if overlaps.size() > 0 and belongs == 0:
		for i in overlaps:
			if i.is_in_group('Enemy') and i.has_method('kill'):
				i.kill(AliveObject.DEATH_TYPE.FALL if !i.force_death_type else i.death_type, 0, null, self.name)
				
	if belongs != 0 and Global.is_mario_collide_area('InsideDetector', $CollisionArea):
		Global._ppd()

	velocity.y += 0.33 * gravity_scale * Global.get_delta(delta)

	position += velocity * Global.get_delta(delta)
	
	$Sprite.rotation_degrees += 6 * (-1 if velocity.x < 0 else 1) * Global.get_delta(delta)
	$Sprite.flip_h = velocity.x < 0

func _on_screen_exited() -> void:
	queue_free()

func _on_tree_exited() -> void:
	if belongs == 0:
		Global.projectiles_count -= 1

func _on_level_complete() -> int:
	var score = 100
	var score_text = ScoreText.new(score, position)
	get_parent().add_child(score_text)
	queue_free()
	return score
