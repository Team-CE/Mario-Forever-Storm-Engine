extends Node2D

export var music: Resource
export var autoscroll_speed: float = 1
export var music_overlay_name: String = ''

var triggered: bool = false
var music_switched: bool = false
var camera: Camera2D

func _ready():
	if music_overlay_name != '' and !is_instance_valid(Global.current_scene.get_node_or_null('HUD/Control')):
		push_error('Please add a Music Overlay as a child node of HUD and name it Control')
		music_overlay_name = ''

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
		if music_overlay_name != '':
			Global.HUD.get_node('Control').display_text(music_overlay_name)

	if triggered:
		if !camera: return
		$StaticBody2D.collision_layer = 0b10 if Global.Mario.controls_enabled else 0
		if position.x > camera.limit_right - 320:
			return
		position.x += autoscroll_speed * Global.get_delta(delta)
