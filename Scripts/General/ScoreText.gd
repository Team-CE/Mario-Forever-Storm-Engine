extends Sprite
class_name ScoreText

var counter = 0
var icounter = 120

func _init(score: int, pos: Vector2 = Vector2.ZERO):
	texture = preload('res://GFX/Texts/Score.png')
# warning-ignore:incompatible_ternary
	rotation = Global.Mario.rotation if is_instance_valid(Global.Mario) else 0
	position = pos + Vector2(0, -8).rotated(rotation)
	hframes = 8
	z_index = 50
	match score:
		1:
			frame = 0
			icounter = 100
		100:
			frame = 1
			icounter = 80
		200:
			frame = 2
			icounter = 100
		500:
			frame = 3
			icounter = 100
		1000:
			frame = 4
			icounter = 150
		2000:
			frame = 5
			icounter = 200
		5000:
			frame = 6
			icounter = 220
		10000:
			frame = 7
			icounter = 300
	
	if score >= 100:
		Global.add_score(score)

func _physics_process(delta) -> void:
	counter += 1 * Global.get_delta(delta)
	if counter < 36:
		position += Vector2(0, -1).rotated(rotation) * Global.get_delta(delta)
	if counter > icounter:
		queue_free()
