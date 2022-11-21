extends Node

onready var tween_out: Tween = $TweenOut
onready var tween_in: Tween = $TweenIn
onready var openmpt = $Openmpt
onready var starmpt = $Starmpt
onready var main: AudioStreamPlayer = $Main
onready var star: AudioStreamPlayer = $Star

# Only most popular ones are listed, but you can add more
const TRACKER_EXTENSIONS = [
	'xm',
	'it',
	's3m',
	'mod',
	'mptm'
]

enum INTERPOLATION {
	DEFAULT = 0,
	NOTHING = 1,
	LINEAR = 2,
	CUBIC = 4,
	SINC = 8
}

func _ready() -> void:
	var file = File.new()
	file.open('res://Music/starman.it', File.READ)
	var length = file.get_len()
	var buffer = file.get_buffer(length)
	
	starmpt.load_module_data(buffer)
	starmpt.set_audio_generator_playback(star)
	starmpt.set_render_interpolation(0)
	starmpt.start()

func play_file(filepath: String, interpolation: int, loop: bool, volume_offset: float) -> void:
	openmpt.stop()
	if is_tracker_type(filepath): init_tracker(filepath, interpolation, loop, volume_offset)
	else: init_stream(filepath, loop, volume_offset)

func init_stream(filepath: String, loop: bool, volume_offset: float) -> void:
	main.stream = load(filepath)
	
	if !main.stream:
		print('[MusicPlayer] Failed to load file using stream loader')
		return
	
	main.stream.loop = loop
	main.volume_db = volume_offset
	main.play()

func init_tracker(filepath: String, interpolation: int, loop: bool, volume_offset: float) -> void:
	var file = File.new()
	var err = file.open(filepath, File.READ)
	if err != OK:
		print('[MusicPlayer] Failed to read ' + filepath + ' using tracker loader')
		return
	
	var length = file.get_len()
	var buffer = file.get_buffer(length)
	
	openmpt.load_module_data(buffer)
	
	if !openmpt.is_module_loaded():
		print('[MusicPlayer] Failed to load file using tracker loader')
		return
	
	var generator = AudioStreamGenerator.new()
	generator.buffer_length = 0.1
	generator.mix_rate = 44100
	main.stream = generator
	
	openmpt.set_audio_generator_playback(main)
	openmpt.set_render_interpolation(interpolation)
	openmpt.set_repeat_count(0 if !loop else -1)
	openmpt.start()
	
	main.volume_db = volume_offset
	main.play()

func is_tracker_type(filepath: String):
	var extension = filepath.split('.')[-1]
	return extension in TRACKER_EXTENSIONS

# Put this to audio_stream: MusicPlayer.get_node('Main')
func fade_out(audio_stream: Object, duration: float, from_vol: float = 0, to_vol: float = -80) -> void:
# warning-ignore:return_value_discarded
	tween_out.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_IN, 0)
# warning-ignore:return_value_discarded
	tween_out.start()
	print('[MusicPlayer] Fading out...')

func fade_in(audio_stream: Object, duration: float, from_vol: float = -80, to_vol: float = 0) -> void:
# warning-ignore:return_value_discarded
	tween_in.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_OUT, 0)
# warning-ignore:return_value_discarded
	tween_in.start()
	print('[MusicPlayer] Fading in...')

func stop_on_pause():
	main.pause_mode = PAUSE_MODE_STOP

func play_on_pause():
	main.pause_mode = PAUSE_MODE_INHERIT

func _on_TweenOut_tween_completed(object, _key):
	object.stop()
	object.volume_db = 0
	print('[MusicPlayer] Fade out complete')

func _on_TweenOut_tween_step(_object, _key, _elapsed, _value):
	#print(value)
	pass

func _on_Main_finished():
	main.pause_mode = PAUSE_MODE_INHERIT
	print('[MusicPlayer] Finished playing')
