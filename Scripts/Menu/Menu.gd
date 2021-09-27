extends Control

export var music: String = ''


func _ready():
  yield(get_tree().create_timer( 1.4 ), 'timeout')
  MusicEngine.play_music(music)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
