extends Node

export var path = ''

var mplayer = music_eng.music_player

func _ready() -> void:
	mplayer.play_music('res://Music/' + path, 0, false, 0, 0, 0) #TOO LOUD!
