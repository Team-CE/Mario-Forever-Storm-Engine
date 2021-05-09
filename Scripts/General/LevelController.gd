extends Node

export var time: int = 360
export var music: String = ''

func _ready():
  Global.time = time
  MusicEngine.play_music(music)
