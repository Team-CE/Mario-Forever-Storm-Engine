extends Node

export var file: Resource #DEPRECATED
export(Array, Resource) var music_list = [null]
export var current_index: int = 0 setget set_current_index
export var playing: bool = true

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
	
	if current_index > music_list.size():
		current_index = music_list.size()

	if !Global.starman_saved:
		if playing:
			MusicPlayer.play_file(music_list[current_index])
		MusicPlayer.play_on_pause()
		MusicPlayer.star.stop()
		MusicPlayer.star.volume_db = 0
	else:
		MusicPlayer.main.stop()

func set_current_index(new_index):
	var list_size = music_list.size()
	if new_index > list_size or new_index < 0:
		new_index = list_size
		printerr('[MusicLoader] Index out of bounds: %i is more than the maximum of %i' % [new_index, list_size])
	current_index = new_index
	if playing:
		play()

func play():
	MusicPlayer.play_file(music_list[current_index])
	playing = true

func _enter_tree():
	Global.music_loader = self

func _exit_tree():
	Global.music_loader = null
