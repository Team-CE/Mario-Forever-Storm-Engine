onready var init = false
var delay_counter: float = 45

var mario = Global.Mario

func _process_movement(brain, delta):
	if delay_counter > 0:
		delay_counter -= 1 * Global.get_delta(delta)
		return

	if !init:
		brain.owner.get_node('AnimatedSprite').speed_scale = 4
		init = true
	
	if !brain.owner.is_on_floor():
		brain.owner.velocity.y += Global.gravity * brain.owner.gravity_scale * Global.get_delta(delta)
	else:
		brain.owner.velocity.y = brain.owner.vars['bounce']
	brain.owner.velocity.x = brain.owner.vars['speed'] * brain.owner.dir
	if brain.owner.is_on_wall():
		brain.owner.turn()

func do_action(brain):
	if brain.custom_script.delay_counter > 1: return
	
	mario.shield_counter = 750
	mario.shield_star = true
	mario.faded = false
	mario.get_node('Sprite').visible = true
	Global.play_base_sound('MAIN_Powerup')
	MusicPlayer.main.stop()
	MusicPlayer.openmpt.stop()
	MusicPlayer.starmpt.start(true)
	MusicPlayer.star.play()
# warning-ignore:return_value_discarded
	MusicPlayer.tween_out.remove(MusicPlayer.star)
	MusicPlayer.star.volume_db = 0
	brain.owner.get_parent().add_child(ScoreText.new(brain.owner.score, brain.owner.position))
	brain.owner.queue_free()
