extends Sprite

var fade: bool

func _init(pos: Vector2 = Vector2.ZERO, long_fade: bool = false):
	texture = preload('res://GFX/Miscellaneous/CheckpointEffect.png')
	position = pos
	if !long_fade:
		modulate.a = 0.55
	fade = long_fade

func _process(delta) -> void:
	modulate.a -= 0.1 * Global.get_delta(delta) if !fade else 0.05 * Global.get_delta(delta) 
	if modulate.a <= 0.01:
		queue_free()
