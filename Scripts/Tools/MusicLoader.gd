extends Node

export var file: Resource
export(MusicPlayer.INTERPOLATION) var interpolation: int
export var volume_offset: float
export var loop: bool = true

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
	MusicPlayer.play_file(file.resource_path, interpolation, loop, volume_offset)
	if !Global.starman_saved:
		MusicPlayer.play_on_pause()
		MusicPlayer.get_node('Star').stop()
		MusicPlayer.get_node('Star').volume_db = 0
	else:
		MusicPlayer.get_node('Main').stop()
