extends Node

onready var tween_out = $TweenOut
onready var tween_in = $TweenIn

# Put this to audio_stream: MusicPlayer.get_node('Main')
func fade_out(audio_stream: Object, duration: float, from_vol: float = 0, to_vol: float = -80) -> void:
  tween_out.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_IN, 0)
  tween_out.start()
  print('Fading out...')

func fade_in(audio_stream: Object, duration: float, from_vol: float = -80, to_vol: float = 0) -> void:
  tween_in.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_OUT, 0)
  tween_in.start()
  print('Fading in...')

func _on_TweenOut_tween_completed(object, key):
  object.stop()
  object.volume_db = 0
  print('Fade out complete')

func _on_TweenOut_tween_step(object, key, elapsed, value):
  #print(value)
  pass
