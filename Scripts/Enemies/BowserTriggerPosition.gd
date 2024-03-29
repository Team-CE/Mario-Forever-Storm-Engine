extends Node2D

export var music: Resource = preload('res://Music/bowser-battle.it')
export var autoscroll_speed: float = 1
export var music_overlay_name: String = ''

var triggered: bool = false
var music_switched: bool = false
var camera: Camera2D

func _ready():
	if music_overlay_name != '' and !Global.current_scene.overlay:
		push_error('Please add a Music Overlay to the scene as a child node of HUD.')
		music_overlay_name = ''

func _physics_process(delta): 
	if !Global.is_getting_closer(-32, position):
		return
	if Global.Mario.position.x > position.x and !music_switched:
		music_switched = true
		if music != null:
			MusicPlayer.play_file(music)
		$StaticBody2D.collision_layer = 0b10000
		camera = Global.current_camera
		if !camera: return
		camera.get_parent().remove_child(camera)
		add_child(camera)
		triggered = true
		if music_overlay_name != '' && music != null:
			Global.current_scene.overlay.display_text(music_overlay_name)

	if triggered:
		if !camera: return
		$StaticBody2D.collision_layer = 0b10000 if Global.Mario.controls_enabled else 0
		if position.x > camera.limit_right - 320:
			return
		position.x += autoscroll_speed * Global.get_delta(delta)
		if not Global.Mario.dead and Global.Mario.global_position.x < global_position.x - 352:
			Global._pll()
