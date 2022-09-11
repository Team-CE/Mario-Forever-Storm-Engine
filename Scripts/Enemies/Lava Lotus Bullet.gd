extends Area2D

var velocity: Vector2
var moving: bool = false
var counter: float = 0

func _ready():
	$AnimationPlayer.play('New Anim')
	pass

func _process(delta):
	if !moving: return
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.seek(2, true)
		$AnimationPlayer.stop()
	position += velocity * Global.get_delta(delta)
		
	var id_overlaps = Global.Mario.get_node_or_null('InsideDetector').get_overlapping_areas()
	if id_overlaps and id_overlaps.has(self):
		Global._ppd()
	
	counter += 1 * Global.get_delta(delta)
	if counter > 300:
		$AnimatedSprite.visible = int(counter / 2) % 2 == 0
	if counter > 400:
		queue_free()
