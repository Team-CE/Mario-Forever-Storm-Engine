extends Area2D
class_name Warp
tool

signal half_warped

enum DIRS {
	DOWN,
	UP,
	RIGHT,
	LEFT
}

enum TYPES {
	IN,
	OUT
}

export var id: int = 0
export(DIRS) var direction: int = DIRS.DOWN
export(TYPES) var type: int = TYPES.IN
export var immediate: bool = false
export var trigger_finish: bool = false
export var additional_options: Dictionary = {
	'set_scene_path': '',
	'add_scene': PackedScene
}
export var out_duration: float = 60
export var custom_warp_sound: Resource
export var show_scene_transition: bool = false

var mario_sprite

var in_icon: StreamTexture = preload('res://GFX/Editor/WarpIcon.png')
var out_icon: StreamTexture = preload('res://GFX/Editor/WarpOutIcon.png')

var disabled: bool = false

var active: bool = false
var counter: float = 0

var state_switched: bool = false

var calc_pos: Vector2
var warp_dir: Vector2 = Vector2.ZERO

var out_node
var finishline = null

var custom_audio: AudioStreamPlayer = null

func _ready() -> void:
	var nodes = get_tree().get_nodes_in_group('Warp')

	for node in nodes:
		if node.id == id and node.type == TYPES.OUT:
			out_node = node
			
	disabled = not out_node and ((not 'set_scene_path' in additional_options or additional_options['set_scene_path'] == '') and (not 'add_scene' in additional_options or not additional_options['add_scene'].is_class('PackedScene'))) and not trigger_finish
	
	if disabled && is_inside_tree():
		printerr('[SE ERROR] No out warp assigned for ID ' + str(id) + ', it will not be functional. Create an out warp or set an additional option.')
		
	if not Engine.editor_hint:
		$Sprite.visible = false
		mario_sprite = Global.Mario.get_node("Sprite")
	
		if immediate and Global.checkpoint_active == -1:
			active = true
			out_node = self
			counter = 61
		
		if custom_warp_sound:
			custom_audio = AudioStreamPlayer.new()
			custom_audio.bus = 'Sounds'
			custom_audio.stream = custom_warp_sound
			add_child(custom_audio)
			
		if trigger_finish:
			yield(get_tree(), 'idle_frame')
			if !Global.current_scene.finish_node:
				printerr('[SE ERROR] No Finish Line found on level. Create one or untick the checkbox for warp ID ' + str(id))
				trigger_finish = false
				disabled = true
			else:
				finishline = Global.current_scene.finish_node

func _physics_process(delta) -> void:
	if Engine.editor_hint:
		$Sprite.texture = in_icon if type == TYPES.IN else out_icon
		
		$Sprite.modulate = Color.from_hsv((id / 30.0) - floor(id / 30.0), 1.0, 1.0)
		$Sprite.flip_v = false if direction == DIRS.DOWN or direction == DIRS.RIGHT else true
		$Sprite.rotation_degrees = -90 if direction == DIRS.RIGHT or direction == DIRS.LEFT else 0
	else:
		if disabled: return
		# Warp Enter
		if Global.Mario.get_node('InsideDetector').get_overlapping_areas().has(self) and not active and type == TYPES.IN and (not trigger_finish or (trigger_finish and counter < 60)):
			if direction == DIRS.DOWN and Input.is_action_pressed('mario_crouch'):
				calc_pos = Vector2(position.x, position.y - 16)
				active = true
				Global.Mario.invulnerable = true
# warning-ignore:standalone_ternary
				Global.play_base_sound('MAIN_Pipe') if !custom_audio else custom_audio.play()
				warp_dir = Vector2.DOWN
				Global.Mario.animate_sprite('Crouching' if Global.state > 0 else 'Stopped')
				Global.Mario.get_node('Sprite').visible = true
			elif direction == DIRS.UP and Input.is_action_pressed('mario_up'):
				calc_pos = Vector2(position.x, position.y + 16 + (30 if Global.state != 0 else 0))
				active = true
				Global.Mario.invulnerable = true
# warning-ignore:standalone_ternary
				Global.play_base_sound('MAIN_Pipe') if !custom_audio else custom_audio.play()
				warp_dir = Vector2.UP
				Global.Mario.animate_sprite('Jumping')
				Global.Mario.get_node('Sprite').visible = true
			elif direction == DIRS.RIGHT and Input.is_action_pressed('mario_right'):
				calc_pos = Vector2(position.x - 16, position.y + 16)
				active = true
				Global.Mario.invulnerable = true
# warning-ignore:standalone_ternary
				Global.play_base_sound('MAIN_Pipe') if !custom_audio else custom_audio.play()
				Global.Mario.animate_sprite('Walking')
				mario_sprite.speed_scale = 5
				mario_sprite.flip_h = false
				warp_dir = Vector2.RIGHT
			elif direction == DIRS.LEFT and Input.is_action_pressed('mario_left'):
				calc_pos = Vector2(position.x + 16, position.y + 16)
				active = true
				Global.Mario.invulnerable = true
# warning-ignore:standalone_ternary
				Global.play_base_sound('MAIN_Pipe') if !custom_audio else custom_audio.play()
				Global.Mario.animate_sprite('Walking')
				mario_sprite.speed_scale = 5
				mario_sprite.flip_h = true
				warp_dir = Vector2.LEFT
		
		if active:
			Global.Mario.controls_enabled = false
			Global.Mario.animation_enabled = false
			Global.Mario.motion_disabled = true
			Global.Mario.position = calc_pos
			Global.Mario.velocity = Vector2.ZERO
			calc_pos += warp_dir * Global.get_delta(delta)
			counter += 1 * Global.get_delta(delta)
			if warp_dir == Vector2.LEFT or warp_dir == Vector2.RIGHT:
				mario_sprite.visible = counter < 36 or counter > 23 + out_duration
			else:
				mario_sprite.visible = true

			Global.Mario.get_node('Sprite').z_index = -10
			if Global.Mario.is_in_shoe:
				Global.Mario.shoe_node.z_index = -9

		# Warp Exit
			if counter > out_duration and not state_switched:
				if 'add_scene' in additional_options and additional_options['add_scene'].is_class('PackedScene'):
					state_switched = true
					var instanced_node = additional_options['add_scene'].instance()
					Global.current_scene.add_child(instanced_node)
					call_deferred('warp_exit')

				elif out_node:
					state_switched = true
					if show_scene_transition:
						SceneTransition.start_transition('FadePixelate', 1.0, true)
						MusicPlayer.star.pause_mode = PAUSE_MODE_PROCESS
						Global.get_tree().paused = true
					warp_exit()

				elif 'set_scene_path' in additional_options and additional_options['set_scene_path'] != '':
					if show_scene_transition:
						Global.goto_scene_with_transition(additional_options['set_scene_path'])
					else:
						Global.goto_scene(additional_options['set_scene_path'])

				elif trigger_finish:
					state_switched = true
					finishline.act(true)
					Global.Mario.visible = false
					warp_dir = Vector2.ZERO
			if counter >= out_duration + 60 and not trigger_finish and !Global.Mario.test_move(Global.Mario.transform, Vector2.ZERO):
				Global.Mario.get_node('Sprite').z_index = 10
				state_switched = false
				counter = 0
				active = false
				Global.Mario.controls_enabled = true
				Global.Mario.animation_enabled = true
				Global.Mario.invulnerable = false
				Global.Mario.motion_disabled = false
				if Global.Mario.is_in_shoe:
					Global.Mario.shoe_node.z_index = 11

func warp_exit():
	emit_signal('half_warped')
	Global.play_base_sound('MAIN_Pipe')
	MusicPlayer.star.pause_mode = PAUSE_MODE_STOP

	if out_node.direction == DIRS.DOWN:
		Global.Mario.crouch = false
		calc_pos = Vector2(out_node.position.x, out_node.position.y - 40 + (24 if Global.state != 0 else 0))
		warp_dir = Vector2.DOWN
		Global.Mario.animate_sprite('Jumping')
	elif out_node.direction == DIRS.UP:
		Global.Mario.crouch = true
		calc_pos = Vector2(out_node.position.x, out_node.position.y + 44)
		warp_dir = Vector2.UP
		Global.Mario.animate_sprite('Crouching' if Global.state > 0 else 'Stopped')
	elif out_node.direction == DIRS.RIGHT:
		Global.Mario.crouch = false
		calc_pos = Vector2(out_node.position.x - 44, out_node.position.y + 15.9)
		warp_dir = Vector2.RIGHT
		Global.Mario.animate_sprite('Walking')
		mario_sprite.speed_scale = 5
		mario_sprite.flip_h = false
	elif out_node.direction == DIRS.LEFT:
		Global.Mario.crouch = false
		calc_pos = Vector2(out_node.position.x + 44, out_node.position.y + 15.9)
		warp_dir = Vector2.LEFT
		Global.Mario.animate_sprite('Walking')
		mario_sprite.speed_scale = 5
		mario_sprite.flip_h = true
