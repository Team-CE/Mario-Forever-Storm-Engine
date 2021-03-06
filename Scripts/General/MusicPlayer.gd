extends Node

onready var tween_out: Tween = $TweenOut
onready var tween_in: Tween = $TweenIn

# Put this to audio_stream: MusicPlayer.get_node('Main')
func fade_out(audio_stream: Object, duration: float, from_vol: float = 0, to_vol: float = -80) -> void:
# warning-ignore:return_value_discarded
  tween_out.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_IN, 0)
# warning-ignore:return_value_discarded
  tween_out.start()
  print('Fading out...')

func fade_in(audio_stream: Object, duration: float, from_vol: float = -80, to_vol: float = 0) -> void:
# warning-ignore:return_value_discarded
  tween_in.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_OUT, 0)
# warning-ignore:return_value_discarded
  tween_in.start()
  print('Fading in...')

func stop_on_pause():
  $Main.pause_mode = PAUSE_MODE_STOP

func play_on_pause():
  $Main.pause_mode = PAUSE_MODE_INHERIT

func _on_TweenOut_tween_completed(object, _key):
  object.stop()
  object.volume_db = 0
  print('Fade out complete')

func _on_TweenOut_tween_step(_object, _key, _elapsed, _value):
  #print(value)
  pass

func _on_Main_finished():
  $Main.pause_mode = PAUSE_MODE_INHERIT
  print('finished')
