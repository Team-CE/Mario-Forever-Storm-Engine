extends CanvasLayer

signal fade_in_ended
signal fade_out_ended

func _ready():
	get_parent().call_deferred('remove_child', self)
	GlobalViewport.vp.call_deferred('add_child', self)

func start_transition(trans_name: String, speed: float = 1.0, repeat_backwards: bool = true) -> void:
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop(true)
		#push_error('[SceneTransition] Transition is already in process.')
		#return

	if repeat_backwards:
# warning-ignore:return_value_discarded
		$AnimationPlayer.connect('animation_finished', self, '_end_transition', [], CONNECT_ONESHOT)

	$AnimationPlayer.playback_speed = speed
	$AnimationPlayer.play(trans_name)

func _end_transition(anim_name: String) -> void:
	emit_signal('fade_in_ended')
	#print('[SceneTransition] Fade in ended')
	#$AnimationPlayer.play_backwards(anim_name)
	$AnimationPlayer.call_deferred('play_backwards', anim_name)
# warning-ignore:return_value_discarded
	$AnimationPlayer.connect('animation_finished', self, '_transition_ended', [], CONNECT_ONESHOT)
	
	# Resuming from pause just in case
	if Global.popup or is_instance_valid(Global.popup): return
	if Global.get_tree().paused:
		Global.get_tree().paused = false

func _transition_ended(_anim_name) -> void:
	emit_signal('fade_out_ended')
	#print('[SceneTransition] Fade out ended')
	$AnimationPlayer.play('RESET')
