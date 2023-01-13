extends Node

export(Array, Resource) var music_list = [null]
export var current_index: int = 0 setget set_current_index
export var playing: bool = true

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
	
	if current_index > music_list.size():
		current_index = music_list.size()
	
	if Global.starman_saved and Global.current_scene.is_class('Level'): return
	
	if playing and music_list[current_index] != null:
		MusicPlayer.play_file(music_list[current_index])
	MusicPlayer.play_on_pause()
	MusicPlayer.star.stop()
	MusicPlayer.star.volume_db = 0

func set_current_index(new_index):
	var list_size = music_list.size()
	if new_index > list_size or new_index < 0:
		new_index = list_size
		printerr('[MusicLoader] Index out of bounds: %i is more than the maximum of %i' % [new_index, list_size])
	current_index = new_index
	play()

func play():
	if music_list[current_index] == null:
		push_warning('[MusicLoader] Skipping missing index')
		return
	playing = true
	if is_instance_valid(Global.Mario) and Global.Mario.shield_star:
		return
	MusicPlayer.play_file(music_list[current_index])
	print('played')

func _enter_tree():
	Global.music_loader = self

func _exit_tree():
	Global.music_loader = null
