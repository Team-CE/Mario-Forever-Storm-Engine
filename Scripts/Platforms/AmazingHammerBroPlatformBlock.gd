extends StaticBody2D

var triggered: bool = false
var t_counter: float = 0
onready var initial_position: Vector2 = position

func _physics_process(delta):
	if triggered:
		_process_trigger(delta)

func _process_trigger(delta):
	t_counter += (1 if t_counter < 200 else 0) * Global.get_delta(delta)
	
	if t_counter < 12:
		position += Vector2(0, (-1 if t_counter < 6 else 1) * Global.get_delta(delta)).rotated(rotation)
	
	if t_counter >= 12:
		position = initial_position
		triggered = false
		t_counter = 0


func hit(_a = false, _b = false):
	if triggered: return
	triggered = true
	Global.play_base_sound('MAIN_Bump')
