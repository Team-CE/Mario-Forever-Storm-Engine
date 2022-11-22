extends Node

onready var tween_out: Tween = $TweenOut
onready var tween_in: Tween = $TweenIn
onready var openmpt = $Openmpt
onready var starmpt = $Starmpt
onready var main: AudioStreamPlayer = $Main
onready var star: AudioStreamPlayer = $Star

# Loading typical music used everywhere right after the game boots.
# Reference these variables instead of loading them in scripts.
var mus_win: AudioTrackerModule = preload('res://Music/complete-level.it')    #Level complete
var mus_death: AudioTrackerModule = preload('res://Music/death.it')           #Mario death
var mus_gameover: AudioTrackerModule = preload('res://Music/gameover.it')     #Game over
var mus_starman: AudioTrackerModule = preload('res://Music/starman.it')       #Starman
var mus_complete: AudioTrackerModule = preload('res://Music/stats.it')        #Map complete

# List of every extension libopenmpt 6 can support.
# Constant is unused for now, comments were left for reference.
#
#const TRACKER_EXTENSIONS = [
#	'mptm', 'mod', 's3m', 'xm', 'it', '669', 'amf', 'ams', 'c67', 'mmcmp',
#	'dbm', 'digi', 'dmf', 'dsm', 'dsym', 'dtm', 'far', 'fmt', 'imf', 'ice',
#	'j2b', 'm15', 'mdl', 'med', 'mms', 'mt2', 'mtm', 'mus', 'nst', 'okt',
#	'plm', 'psm', 'pt36', 'ptm', 'sfx', 'sfx2', 'st26', 'stk', 'stm', 'stx',
#	'stp', 'symmod', 'ult', 'wow', 'gdm', 'mo3', 'oxm', 'umx', 'xpk', 'ppm'
#]

# NOTHING is typical for og .mod and some .s3m files, use LINEAR for everything else.
# CUBIC and SINC generally suck playing tracker music, but complex trackers may sound
# better with these.
enum INTERPOLATION {
	DEFAULT = 0,
	NOTHING = 1,
	LINEAR = 2,
	CUBIC = 4,
	SINC = 8
}

func _ready() -> void:
	starmpt.load_module_data(mus_starman.data)
	starmpt.set_audio_generator_playback(star)
	starmpt.set_render_interpolation(INTERPOLATION.LINEAR)
	#starmpt.start()

func play_file(file: Resource, interpolation: int, loop: bool, volume_offset: float) -> void:
	if !file:
		printerr('[MusicPlayer] Invalid resource')
		return
	if ClassDB.get_parent_class(file.get_class()) == 'AudioStream':
		init_stream(file, loop, volume_offset)
	else:
		if 'data' in file:
			init_tracker(file.data, interpolation, loop, volume_offset)
		else:
			printerr('[MusicPlayer] No audio data found in tracker')

func init_stream(audio: AudioStream, loop: bool, volume_offset: float) -> void:
	if !audio:
		printerr('[MusicPlayer] Failed to load file using stream loader')
		return
	
	main.stream = audio
	main.stream.loop = loop
	main.volume_db = volume_offset
	main.play()
	print('[MusicPlayer] Loaded stream audio')

func init_tracker(audio: PoolByteArray, interpolation: int, loop: bool, volume_offset: float) -> void:
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

#func is_tracker_type(filepath: String) -> bool:
#	var extension = filepath.get_extension()
#	if !extension:
#		return false
#	return extension in TRACKER_EXTENSIONS

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
