extends Node

var music_player = FLMusicLib.new()

func _ready():
	add_child(music_player);
	music_player.set_gme_buffer_size(2048 * 5)
