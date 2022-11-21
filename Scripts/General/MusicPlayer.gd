extends Node

onready var tween_out: Tween = $TweenOut
onready var tween_in: Tween = $TweenIn
onready var openmpt = $Openmpt
onready var starmpt = $Starmpt
onready var main: AudioStreamPlayer = $Main
onready var star: AudioStreamPlayer = $Star

const TRACKER_EXTENSIONS = [
	'mptm', 'mod', 's3m', 'xm', 'it', '669', 'amf', 'ams', 'c67', 'mmcmp',
	'dbm', 'digi', 'dmf', 'dsm', 'dsym', 'dtm', 'far', 'fmt', 'imf', 'ice',
	'j2b', 'm15', 'mdl', 'med', 'mms', 'mt2', 'mtm', 'mus', 'nst', 'okt',
	'plm', 'psm', 'pt36', 'ptm', 'sfx', 'sfx2', 'st26', 'stk', 'stm', 'stx',
	'stp', 'symmod', 'ult', 'wow', 'gdm', 'mo3', 'oxm', 'umx', 'xpk', 'ppm'
]

enum INTERPOLATION {
	DEFAULT = 0,
	NOTHING = 1,
	LINEAR = 2,
	CUBIC = 4,
	SINC = 8
}

var is_tracker: bool
var audio

func _ready() -> void:
	var file = File.new()
	var err = file.open('res://Music/starman.it', File.READ)
	if err != OK:
		print_debug('err: ', err, '\n See: https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-error')
		return
	
	var length = file.get_len()
	var buffer = file.get_buffer(length)
	file.close()
	file = null
	
	starmpt.load_module_data(buffer)
	starmpt.set_audio_generator_playback(star)
	starmpt.set_render_interpolation(INTERPOLATION.DEFAULT)
	#starmpt.start()

func play_file(filepath: String, interpolation: int, loop: bool, volume_offset: float) -> void:
	openmpt.stop()
	is_tracker = is_tracker_type(filepath)
	if is_tracker:
		init_tracker(filepath, interpolation, loop, volume_offset)
	else:
		init_stream(filepath, loop, volume_offset)

func init_stream(filepath: String, loop: bool, volume_offset: float) -> void:
	audio = load(filepath)
	
	if !audio:
		printerr('[MusicPlayer] Failed to load file using stream loader')
		return
	
	main.stream = audio
	main.stream.loop = loop
	main.volume_db = volume_offset
	main.play()

func init_tracker(filepath: String, interpolation: int, loop: bool, volume_offset: float) -> void:
	var file = File.new()
	var err = file.open(filepath, File.READ)
	if err != OK:
		printerr('[MusicPlayer] Failed to read path ' + filepath + ' using tracker loader')
		return
	
	var length = file.get_len()
	audio = file.get_buffer(length)
	
	file.close()
	file = null
	
	openmpt.load_module_data(audio)
	
	if !openmpt.is_module_loaded():
		printerr('[MusicPlayer] Failed to load file using tracker loader')
		return
	
	var generator = AudioStreamGenerator.new()
	#generator.buffer_length = 0.5
	generator.mix_rate = 44100
	main.stream = generator
	
	openmpt.set_audio_generator_playback(main)
	openmpt.set_render_interpolation(interpolation)
	openmpt.set_repeat_count(0 if !loop else -1)
	openmpt.start()
	
	main.volume_db = volume_offset
	main.play()

func is_tracker_type(filepath: String) -> bool:
	var extension = filepath.get_extension()
	if !extension:
		return false
	return extension in TRACKER_EXTENSIONS

# Put this to audio_stream: MusicPlayer.main
func fade_out(audio_stream: Object, duration: float, from_vol: float = 0, to_vol: float = -80) -> void:
# warning-ignore:return_value_discarded
	tween_out.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_IN, 0)
# warning-ignore:return_value_discarded
	tween_out.start()
	print('[MusicPlayer] Fading out for ', duration, 's...')

func fade_in(audio_stream: Object, duration: float, from_vol: float = -80, to_vol: float = 0) -> void:
# warning-ignore:return_value_discarded
	tween_in.interpolate_property(audio_stream, 'volume_db', from_vol, to_vol, duration, Tween.TRANS_SINE, Tween.EASE_OUT, 0)
# warning-ignore:return_value_discarded
	tween_in.start()
	print('[MusicPlayer] Fading in for ', duration, 's...')

func stop_on_pause():
	main.pause_mode = PAUSE_MODE_STOP

func play_on_pause():
	main.pause_mode = PAUSE_MODE_INHERIT

func _on_TweenOut_tween_completed(object, _key):
	object.stop()
	object.volume_db = 0
	print('[MusicPlayer] Fade out complete')

func _on_TweenOut_tween_step(_object, _key, _elapsed, _value):
	#print(_value)
	pass

func _on_Main_finished():
	main.pause_mode = PAUSE_MODE_INHERIT
	print('[MusicPlayer] Finished playing')
