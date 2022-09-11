extends Node2D

export var music: Resource
export var autoscroll_speed: float = 1

var triggered: bool = false
var music_switched: bool = false
var camera: Camera2D

func _process(delta): 
	if !Global.is_getting_closer(-32, position):
		return
	if Global.Mario.position.x > position.x and !music_switched:
		music_switched = true
		MusicPlayer.get_node('Main').stream = music
		MusicPlayer.get_node('Main').play()
		$StaticBody2D.collision_layer = 0b10
		camera = Global.current_camera
		if !camera: return
		camera.get_parent().remove_child(camera)
		add_child(camera)
		triggered = true

	if triggered:
		if !camera: return
		$StaticBody2D.collision_layer = 0b10 if Global.Mario.controls_enabled else 0
		if position.x > camera.limit_right - 320:
			return
		position.x += autoscroll_speed * Global.get_delta(delta)
