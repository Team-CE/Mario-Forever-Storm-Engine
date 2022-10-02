extends StaticBody2D
tool

enum SIZES {
	SMALL,
	MEDIUM,
	LARGE
}

export(SIZES) var size: int = SIZES.SMALL setget on_size_changed

var freeze_sprite_counter: float
var frozen: bool = true

func _ready():
	if !Engine.editor_hint:
		$IceSprite.playing = true

func _physics_process(delta):
	if Engine.editor_hint:
		return
	if !frozen:
		return
	freeze_sprite_counter += 1 * Global.get_delta(delta)
		
	if freeze_sprite_counter > 80:
		freeze_sprite_counter = 0
		$IceSprite.frame = 0

func on_size_changed(new):
	size = new
	$IceSprite.set_animation('large' if new == SIZES.LARGE else 'medium' if new == SIZES.MEDIUM else 'small')
	if !Engine.editor_hint:
		var sizer: Vector2
		if new == SIZES.SMALL:
			return
		elif new == SIZES.MEDIUM:
			sizer = Vector2(16, 32)
		elif new == SIZES.LARGE:
			sizer = Vector2(32, 32)
			
		var shape = $CollisionShape2D.shape.duplicate()
		shape.extents = sizer
		$CollisionShape2D.shape = shape
		$Area2D/CollisionShape2D.shape = shape

func _on_body_entered(body) -> void:
	if Engine.editor_hint: return
	
	if 'Fireball'.to_lower() in body.get_name().to_lower() and 'belongs' in body and frozen:
		unfreeze()
		body.explode()

func unfreeze():
	visible = false
	frozen = false
	if is_instance_valid(get_node_or_null('CollisionShape2D')): $CollisionShape2D.set_deferred('disabled', true)
	if is_instance_valid(get_node_or_null('Area2D/CollisionShape2D')): $Area2D/CollisionShape2D.set_deferred('disabled', true)
	get_node('ice2').play()
	var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
	for i in 4:
		var debris_effect = BrickEffect.new(position + Vector2(0, -16), speeds[i], $IceSprite.frames)
		get_parent().add_child(debris_effect)

func _on_AudioStreamPlayer2D_finished():
	if Engine.editor_hint:
		return
	queue_free()
