extends Sprite
class_name ScoreText

var counter = 0

func _init(score : int, pos: Vector2 = Vector2.ZERO):
	texture = preload('res://GFX/Texts/Score.png')
	position = pos
	hframes = 8
	match score:
		1:
			frame = 0
		100:
			frame = 1
		200:
			frame = 2
		500:
			frame = 3
		1000:
			frame = 4
		2000:
			frame = 5
		5000:
			frame = 6
		10000:
			frame = 7
	
	if score >= 100:
		Global.add_score(score)

func _process(delta) -> void:
	counter += 1 * Global.get_delta(delta)
	if counter < 40:
		position.y -= 1 * Global.get_delta(delta)
	if counter > 120:
		queue_free()
