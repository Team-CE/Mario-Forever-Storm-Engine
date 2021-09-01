extends Control

export var music: String = ''


func _ready():
  MusicEngine.play_music(music)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
