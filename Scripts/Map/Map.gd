extends Node2D

var internal_offset: float = 0

export var music: Resource
export var mario_speed: float = 1
export var mario_fast_speed: float = 15
export var stop_points: Array = []
export var level_scenes: Array = []

export var save_script: Script
var inited_save_script

var current_speed: float = mario_speed
var stopped: bool = false
var is_lerping: bool = false

var fading_out: bool = false
var circle_size: float = 0.623

onready var sprite = Global.Mario.get_node('Sprite')

func get_class(): return 'Map'
func is_class(name) -> bool: return name == 'Map' or .is_class(name)

func _ready() -> void:
	Global.Mario.invulnerable = true
	Global.Mario.movement_type = Global.Mario.Movement.NONE
	MusicPlayer.get_node('Main').stream = music
	MusicPlayer.get_node('Main').play()
	
	if Global.musicBar > 0.01:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
	MusicPlayer.play_on_pause()

	Global.call_deferred('reset_audio_effects')
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if save_script:
		inited_save_script = save_script.new()
		if inited_save_script.has_method('_ready_mixin'):
			inited_save_script._ready_mixin(self)
	
	if Global.levelID > 0:
		$MarioPath/PathFollow2D.offset = stop_points[Global.levelID - 1]

func _process(delta: float) -> void:
	sprite.animation = 'Walking' if Global.shoe_type == 0 else 'Stopped'
	if Global.shoe_type and !stopped and is_instance_valid(Global.Mario.shoe_node):
		Global.Mario.get_node('AnimationPlayer').play('Small' if Global.state == 0 else 'Big')
		Global.Mario.shoe_node.get_node('AnimatedSprite').offset.y = -12 if Global.state == 0 else 16
	sprite.speed_scale = 20 if !stopped else 5
	sprite.offset.y = 0 - sprite.frames.get_frame(sprite.animation, sprite.frame).get_size().y + 32 if Global.state > 0 else -12

	if inited_save_script and inited_save_script.has_method('_process_mixin'):
		inited_save_script._process_mixin(self, delta)

	if $MarioPath/PathFollow2D.offset < stop_points[Global.levelID]:
		$MarioPath/PathFollow2D.offset += current_speed * Global.get_delta(delta)
		
		if Input.is_action_just_pressed('mario_jump'):
			if !is_lerping:
				is_lerping = true
	if is_lerping:
		current_speed = lerp(current_speed, mario_fast_speed, 0.1 * Global.get_delta(delta))

	if $MarioPath/PathFollow2D.offset > stop_points[Global.levelID]:
		$MarioPath/PathFollow2D.offset = stop_points[Global.levelID]
		stopped = true
		
	if stopped and not fading_out:
		var pj = $ParallaxBackground/ParallaxLayer/PressJump
		if pj.modulate.a < 1:
			pj.modulate.a += 0.1 * Global.get_delta(delta)
		else:
			pj.modulate.a = 1
		var music_overlay = get_node_or_null('ParallaxBackground/Control')
		if music_overlay and music_overlay.get_node('AnimationPlayer').current_animation_position < 4.0:
			music_overlay.get_node('AnimationPlayer').seek(4)

	if Input.is_action_just_pressed('mario_jump') and !fading_out and stopped:
		fading_out = true
		var fadeout = $fadeout.duplicate()
		get_node('/root').add_child(fadeout)
		fadeout.play()
		MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 2.0)
	
	if fading_out:
		circle_size -= 0.012 * Global.get_delta(delta)
		$ParallaxBackground/ParallaxLayer/Transition.visible = true
		$ParallaxBackground/ParallaxLayer/Transition.material.set_shader_param('circle_size', circle_size)
	else:
		$ParallaxBackground/ParallaxLayer/Transition.visible = false
		
	if circle_size <= -0.1:
		Global.goto_scene(level_scenes[Global.levelID])
		Global.Mario.invulnerable = false


