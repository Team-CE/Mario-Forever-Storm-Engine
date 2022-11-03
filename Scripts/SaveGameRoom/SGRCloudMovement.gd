extends AnimatedSprite

onready var pos: Vector2 = position
onready var timer: float = rand_range(0, 360)

func _ready():
	pass

func _physics_process(delta):
	position.y = pos.y + 5 * cos(timer)
	position.x = pos.x + 20 * sin(timer)
	timer += 0.02 * Global.get_delta(delta)
