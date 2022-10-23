onready var init = false
var delay_counter: float = 1

var mario = Global.Mario

func _process_movement(brain, delta):
	if delay_counter > 0:
		delay_counter -= 1 * Global.get_delta(delta)
		return

	if !init:
		brain.owner.get_node('AnimatedSprite').speed_scale = 4
		init = true

func do_action(brain):
	if brain.custom_script.delay_counter > 1: return
	if Global.starman_saved:
		return
	
	mario.get_node('Sprite').material.set_shader_param('mixing', true)
	mario.get_node('Sprite').visible = true
	#Global.lives -= 1 # ...
	Global.starman_saved = true
	Global.play_base_sound('MAIN_Powerup')
