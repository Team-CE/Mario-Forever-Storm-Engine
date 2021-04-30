extends Node

export var path = ''

var mplayer = global.music_player

func _ready():
	mplayer.play_music('res://Music/' + path, 0, false, 0, 0, 0)
