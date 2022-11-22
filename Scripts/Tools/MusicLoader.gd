extends Node

export var file: Resource
export(MusicPlayer.INTERPOLATION) var interpolation: int
export var volume_offset: float
export var loop: bool = true
export var play: bool = true

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))

	if play:
		MusicPlayer.play_file(file, interpolation, loop, volume_offset)
	if !Global.starman_saved:
		MusicPlayer.play_on_pause()
		MusicPlayer.star.stop()
		MusicPlayer.star.volume_db = 0
	else:
		MusicPlayer.main.stop()

func change_track(new_file: Resource, new_interpolation: int = interpolation, new_loop: bool = loop, new_volume_offset: float = volume_offset, change_now: bool = true):
	file = new_file
	interpolation = new_interpolation
	loop = new_loop
	volume_offset = new_volume_offset
	if change_now:
		play_again()

func play_again():
	MusicPlayer.play_file(file, interpolation, loop, volume_offset)

func _enter_tree():
	Global.music_loader = self

func _exit_tree():
	Global.music_loader = null
