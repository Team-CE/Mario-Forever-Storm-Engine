extends Node

export var path = ''

var mplayer = music_eng.music_player

func _ready() -> void:
	play_music(path)

func play_music(path) -> void:
	mplayer.play_music('res://Music/' + path, 0, false, 0, 0, 0)
