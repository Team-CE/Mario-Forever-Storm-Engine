extends Node

const MUSIC_FOLDER = 'res://Music/'

var music_player

var volume: float setget set_volume

func _ready() -> void:
  return;
  music_player = FLMusicLib.new()
  music_player.set_gme_buffer_size(2048 * 5)
  add_child(music_player)
  music_player.connect('track_ended', self, 'track_ended');

func play_music(mus_name: String, loop: bool = true, loopStart: int = -1, loopEnd: int = -1, track: int = 0) -> void:
  print('[Music Engine] Playing: ' + mus_name)
  return;
  music_player.play_music(MUSIC_FOLDER + mus_name, track, loop, loopStart, loopEnd, 0)

func set_volume(vol: float) -> void:
  return;
  volume = vol
  music_player.set_volume(vol)

func track_ended() -> void:
  push_warning('Track is ended!')

