extends Node2D

# warning-ignore:unused_signal
signal overlay_changed
# warning-ignore:unused_signal
signal quality_changed
# warning-ignore:unused_signal
signal press_jump_text_appeared

var internal_offset: float = 0

export var mario_speed: float = 1
export var mario_fast_speed: float = 15
export var stop_points: Array = []
export var level_scenes: Array = []

var current_speed: float = mario_speed
var stopped: bool = false
var ooawel: bool = false
var is_lerping: bool = false
var is_swimming: bool = false

var fading_out: bool = false
var circle_size: float = 0.624

var overlay: Control = null # Music overlay

onready var sprite = Global.Mario.get_node('Sprite')

func get_class(): return 'Map'
func is_class(name) -> bool: return name == 'Map' or .is_class(name)

func _ready() -> void:
	Global.Mario.invulnerable = true
	Global.Mario.movement_type = Global.Mario.Movement.NONE
	if Global.starman_saved:
		Global.Mario.get_node('Sprite').material.set_shader_param('mixing', true)
		
	MusicPlayer.play_on_pause()

	Global.call_deferred('reset_audio_effects')
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if Global.levelID == 99:
		Global.levelID = 0
	
	if Global.levelID > 0:
		while $MarioPath/PathFollow2D.offset < stop_points[Global.levelID - 1]:
			$MarioPath/PathFollow2D.offset += 4
			for dot in $Dots.get_children():
				dot._physics_process(1)
	
	yield(get_tree(), 'idle_frame')
	var cam = Global.get_current_camera()
	cam.smoothing_enabled = true

func _input(event):
	if !Global.debug:
		return
	if event is InputEventKey and event.pressed and !event.is_echo():
		if Input.is_action_pressed('debug_shift') and event.scancode == 52:
			Global.levelID += 1
			Global.goto_scene(Global.current_scene.filename)

func _on_swim():
	if !is_swimming:
		return
	sprite.animation = 'SwimmingStart'

func _physics_process(delta: float) -> void:
	if Global.shoe_type == 0:
		if !is_swimming:
			sprite.animation = 'Walking'
			sprite.speed_scale = 20 if !stopped else 5
		else:
			sprite.speed_scale = 1
			if sprite.frame > 5:
				sprite.animation = 'SwimmingLoop'
# warning-ignore:return_value_discarded
				get_tree().create_timer(1.0, false).connect('timeout', self, '_on_swim')
	else:
		sprite.animation = 'Stopped'
		if !stopped and is_instance_valid(Global.Mario.shoe_node):
			Global.Mario.get_node('AnimationPlayer').play('Small' if Global.state == 0 else 'Big')
			Global.Mario.shoe_node.get_node('AnimatedSprite').offset.y = -12 if Global.state == 0 else 16

	sprite.offset.y = 0 - sprite.frames.get_frame(sprite.animation, sprite.frame).get_size().y + 32 if Global.state > 0 else -12

	if $MarioPath/PathFollow2D.offset < stop_points[Global.levelID]:
		$MarioPath/PathFollow2D.offset += current_speed * Global.get_delta(delta)
		
		if Input.is_action_just_pressed('mario_jump') && !is_lerping:
			is_lerping = true
	if is_lerping:
		current_speed = lerp(current_speed, mario_fast_speed, 0.1 * Global.get_delta(delta))

	if $MarioPath/PathFollow2D.offset > stop_points[Global.levelID]:
		$MarioPath/PathFollow2D.offset = stop_points[Global.levelID]
		stopped = true
		if !ooawel:
			emit_signal('press_jump_text_appeared')
			ooawel = true
		
	if stopped and not fading_out:
		var pj = $ParallaxBackground/ParallaxLayer/PressJump
		if pj.modulate.a < 1:
			pj.modulate.a += 0.1 * Global.get_delta(delta)
		else:
			pj.modulate.a = 1
		var music_overlay = overlay
		if music_overlay and music_overlay.get_node('AnimationPlayer').current_animation_position < 4.0:
			music_overlay.get_node('AnimationPlayer').seek(4)

	if Input.is_action_just_pressed('mario_jump') and !fading_out and stopped:
		fading_out = true
		var fadeout = $fadeout.duplicate()
		get_node('/root').add_child(fadeout)
		fadeout.play()
		MusicPlayer.fade_out(MusicPlayer.main, 2.0)
	
	if fading_out:
		circle_size -= 0.012 * Global.get_delta(delta)
		$ParallaxBackground/ParallaxLayer/Transition.visible = true
		$ParallaxBackground/ParallaxLayer/Transition.material.set_shader_param('circle_size', circle_size)
	else:
		$ParallaxBackground/ParallaxLayer/Transition.visible = false
		
	if circle_size <= -0.1:
		Global.goto_scene(level_scenes[Global.levelID])
		Global.Mario.invulnerable = false


