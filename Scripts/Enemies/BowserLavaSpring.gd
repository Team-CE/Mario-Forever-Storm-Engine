extends Area2D

var moving: bool = false
onready var init_pos = position.y
var timer: float
var wave: float

func _process(delta):
	if !moving: return
	
	timer += 0.1 * Global.get_delta(delta)
	position.y = init_pos + wave * cos(timer)
	if wave > 0:
		wave -= 0.1 * Global.get_delta(delta)
	else:
		wave = 0


func _on_area_entered(area):
	if 'motion_wave' in area:
		wave = area.motion_wave
		moving = true
		area.motion_wave -= 4
