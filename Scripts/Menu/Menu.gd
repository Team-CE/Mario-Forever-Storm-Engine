extends Control

const CONTROLS_ARRAY = [
	'mario_up',
	'mario_crouch',
	'mario_left',
	'mario_right',
	'mario_jump',
	'mario_fire',
	'ui_pause'
]
const CONTROLS_VALUES: Dictionary = {}

export var music: Resource						#MENU Music
export var music_credits: Resource		#CREDITS Music
export var credits_scene: String

var sel = 0
var screen = 0
var selLimit
var screen_changed = 0
#const popup_node = preload('res://Objects/Tools/PopupMenu.tscn')
#const prompt_node = preload('res://Objects/Tools/PopupMenu/RestartPrompt.tscn')
#var popup: CanvasLayer = null

var fading_in = true
var fading_out = false
onready var circle_size = 0

onready var pointer = $Buttons/Control/Pointer
var pointer_pos: float
var pos_y: float
var force_pos = true

onready var controls_enabled: bool = false
onready var controls_changing: bool = false
onready var assigned: bool = false

func get_class(): return 'Menu'
func is_class(name) -> bool: return name == 'Menu' or .is_class(name)

func _ready() -> void:
	if Global.restartNeeded:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		fading_in = false
		controls_enabled = true
		
		updateControls()
		updateNotes()
		screen = 1
		sel = 12
		Global.restartNeeded = false
		$TransitionLayer/Transition.material.set_shader_param('circle_size', 0.624)
		
		MusicPlayer.play_file(music)
		MusicPlayer.play_on_pause()
		return

	pos_y = 359
	$TransitionLayer/Transition.material.set_shader_param('circle_size', circle_size)
	
	$fadeout.play()
	yield(get_tree().create_timer( 1.2 ), 'timeout')
	if !Global.saveFileExists:
		saveOptions()
	MusicPlayer.play_file(music)
	MusicPlayer.play_on_pause()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	updateControls()
	
func _physics_process(delta) -> void:
	if controls_enabled:
		controls()
	
	if fading_out:
		circle_size -= 0.012 * Global.get_delta(delta)
		$TransitionLayer/Transition.visible = true
		$TransitionLayer/Transition.material.set_shader_param('circle_size', circle_size)
	else:
		$TransitionLayer/Transition.visible = false
	
	if fading_in:
		circle_size += 0.012 * Global.get_delta(delta)
		$TransitionLayer/Transition.visible = true
		$TransitionLayer/Transition.material.set_shader_param('circle_size', circle_size)
		if circle_size > 0.624:
			$TransitionLayer/Transition.visible = false
			circle_size = 0.624
			fading_in = false
			controls_enabled = true
	
	if (not force_pos):
		$S_Start.position.y += (pos_y - $S_Start.position.y) * 0.4 * Global.get_delta(delta)
	else:
		$S_Start.position.y = pos_y # Used to fix cursor position between transitions
		force_pos = false
	if (screen_changed != screen):
		screen_changed = screen
		force_pos = true
				
	var base_y = screen * 480
	$S_Start/Camera2D.limit_top = base_y
	$S_Start/Camera2D.limit_bottom = base_y + 480
		
	match screen:
		0:
			pos_y = 359 + (29 * sel)
			$S_Start.position.x = 248
			selLimit = 2
			pointer_pos = 0
			pointer.rect_position.y = 0
		1:
			$S_Start.position.x = 188
			selLimit = 13
			updateOptions()
			$Credits.hide()
			pointer_pos = max(-(selLimit * 37.5) + 340, min(0, -(sel * 37.5) + 160))
			pointer.rect_position.y += (pointer_pos - pointer.rect_position.y) * 0.4 * Global.get_delta(delta)
			pos_y = 506 + (37.5 * sel) + pointer_pos
		2:
			pos_y = 988 + (48 * sel) if sel < 7 else 1004 + (48 * sel)
			$S_Start.position.x = 156
			selLimit = 8
		3:
			pos_y = 1920 + 216
			$S_Start.position.x = 240
			selLimit = 0
			$Credits.position.y -= 1 * Global.get_delta(delta)
			$Credits.show()
		
func onMenuCursorUpdate() -> void:
	#if Global.effects:
	#	var effect = MarioHeadEffect.new($S_Start.position)
	#	add_child(effect)
# warning-ignore:standalone_ternary
	$select_main.play() if screen < 2 else $select_controls.play()
	if screen == 1: updateNotes()
		
func controls() -> void:
	if Input.is_action_just_pressed('ui_down') and screen != 3:
		sel = 0 if sel + 1 > selLimit else sel + 1
		onMenuCursorUpdate()
	elif Input.is_action_just_pressed('ui_up') and screen != 3:
		sel = selLimit if sel - 1 < 0 else sel - 1
		onMenuCursorUpdate()
	
	match screen:
		0:		# _____ MAIN _____
			if Input.is_action_just_pressed('ui_accept'):
				match sel:
					0:
						controls_enabled = false
						if !Global.saveFileExists:
							saveOptions()
						$letsgo.play()
						MusicPlayer.fade_out(MusicPlayer.main, 5.0)
						yield(get_tree().create_timer( 2.5 ), 'timeout')
						var fadeout = $fadeout.duplicate()
						get_node('/root').add_child(fadeout)
						fadeout.play()
						fading_out = true
						yield(get_tree().create_timer( 1.2 ), 'timeout')
						fading_out = false
						Global.goto_scene(ProjectSettings.get_setting('application/config/save_game_room_scene'))
					1:
						screen += 1
						sel = 0
						$enter_options.play()
						updateNotes()
					2:
						controls_enabled = false
						$enter_options.play()
						MusicPlayer.fade_out(MusicPlayer.main, 3.0)
						yield(get_tree().create_timer( 1 ), 'timeout')
						fading_out = true
						yield(get_tree().create_timer( 1.2 ), 'timeout')
						get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
						
		1:		# _____ OPTIONS _____
			if Input.is_action_just_pressed('ui_accept'):
				match sel:
					4:
						screen = 2
						sel = 0
						$enter_options.play()
					12:
						$enter_options.play()
						if credits_scene:
							if !Global.saveFileExists:
								saveOptions()
							Global.goto_scene(credits_scene)
						else:
							screen = 3
							sel = 0
							$Credits.position.y = 1920 + $Credits.texture.get_height() / 2
							MusicPlayer.play_file(music_credits)
					13:
						$enter_options.play()
						saveOptions()
						#if Global.restartNeeded:
						#	Global.restartNeeded = false
						#	promptRestart()
						#else:
						screen = 0
						sel = 1
			if Input.is_action_just_pressed('ui_right'):
				match sel:
					0:
						if Global.soundBar < 0.99:
							Global.soundBar += 0.1
							if is_nan(linear2db(Global.soundBar)): Global.soundBar = 1.0
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear2db(Global.soundBar))
							$tick.play()
							print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Sounds')))
					1:
						if Global.musicBar < 0.99:
							Global.musicBar += 0.1
							if is_nan(linear2db(Global.musicBar)): Global.musicBar = 1.0
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
							$tick.play()
							print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')))
					2:
						if !Global.effects:
							Global.effects = true
							$change.play()
					3:
						if Global.scroll < 2:
							Global.scroll += 2
							$change.play()
					5:
						if Global.quality < 2:
							Global.quality += 1
							$change.play()
					6:
						if Global.scaling < 1:
							Global.scaling += 1
							$change.play()
							saveOptions()
							yield(get_tree(), 'idle_frame')
							updateNotes()
					7:
						if !OS.vsync_enabled:
							OS.vsync_enabled = true
							$change.play()
					8:
						if !Global.rpc:
							Global.rpc = true
							$change.play()
					9:
						if !Global.autopause:
							Global.autopause = true
							$change.play()
					10:
						if !Global.overlay:
							Global.overlay = true
							$change.play()
					11:
						if !Global.autosave:
							Global.autosave = true
							$change.play()
							
			elif Input.is_action_just_pressed('ui_left'):
				match sel:
					0:
						if Global.soundBar > 0.0001:
							Global.soundBar -= 0.1
							if is_nan(linear2db(Global.soundBar)): Global.soundBar = 0
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear2db(Global.soundBar))
							$tick.play()
							print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Sounds')))
					1:
						if Global.musicBar > 0.0001:
							Global.musicBar -= 0.1
							if is_nan(linear2db(Global.musicBar)): Global.musicBar = 0
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
							$tick.play()
							print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')))
					2:
						if Global.effects:
							Global.effects = false
							$change.play()
					3:
						if Global.scroll > 0:
							Global.scroll -= 2
							$change.play()
					5:
						if Global.quality > 0:
							Global.quality -= 1
							$change.play()
					6:
						if Global.scaling > 0:
							Global.scaling -= 1
							$change.play()
							saveOptions()
							updateNotes()
					7:
						if OS.vsync_enabled:
							OS.vsync_enabled = false
							$change.play()
					8:
						if Global.rpc:
							Global.rpc = false
							$change.play()
					9:
						if Global.autopause:
							Global.autopause = false
							$change.play()
					10:
						if Global.overlay:
							Global.overlay = false
							$change.play()
					11:
						if Global.autosave:
							Global.autosave = false
							$change.play()
			elif Input.is_action_just_pressed('ui_cancel'):
				screen = 0
				sel = 1
				$enter_options.play()
				updateControls()
				saveOptions()
		2:		# _____ CONTROLS _____
			if Input.is_action_just_pressed('ui_accept') and sel < 7:
				get_node('Label' + str(sel)).text = '...'
				controls_changing = true
				controls_enabled = false
				get_tree().set_input_as_handled()
			
			if Input.is_action_just_pressed('ui_accept') and sel == 7:
				InputMap.load_from_globals()
				updateControls()
				$enter_options.play()
			if (
				Input.is_action_just_pressed('ui_cancel') or
				Input.is_action_just_pressed('ui_accept') and
				sel == 8
			) and not controls_changing:
				screen = 1
				sel = 4
				controls_changing = false
				controls_enabled = true
				$enter_options.play()
				updateControls()
				saveOptions()
		3:		# _____ CREDITS _____
			if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept'):
				screen = 1
				sel = 12
				MusicPlayer.play_file(music)

func _input(event) -> void:
	if event is InputEventKey and event.pressed and controls_changing and not event.echo:
		if not event.is_action('ui_cancel') or sel == 6:
			var scancode = OS.get_scancode_string(event.scancode)
			get_node('Label' + str(sel)).text = scancode
			for old_event in InputMap.get_action_list(CONTROLS_ARRAY[sel]):
				InputMap.action_erase_event(CONTROLS_ARRAY[sel], old_event)
			InputMap.action_add_event(CONTROLS_ARRAY[sel], event)
			$select_main.play()
		else:
			updateControls()
		assigned = true
	if event is InputEventKey and not event.pressed and controls_changing and assigned:
		controls_changing = false
		controls_enabled = true
		assigned = false
	
func updateOptions() -> void:
	pointer.get_node('SoundBar').frame = round(Global.soundBar * 10.0)
	pointer.get_node('MusicBar').frame = round(Global.musicBar * 10.0)
	pointer.get_node('Effects').frame = Global.effects
	pointer.get_node('Scroll').frame = Global.scroll
	pointer.get_node('Quality').frame = Global.quality
	pointer.get_node('Scaling').frame = Global.scaling
	pointer.get_node('VSync').frame = OS.vsync_enabled
	pointer.get_node('RPC').frame = Global.rpc
	pointer.get_node('Autopause').frame = Global.autopause
	pointer.get_node('Overlay').frame = Global.overlay
	pointer.get_node('Autosave').frame = Global.autosave

func updateNotes() -> void:
	var note = $Buttons/Note
	if note.frames.has_animation(str(sel)):
		note.animation = str(sel)
		note.visible = true
	else:
		note.visible = false
	note.frame = 0 if sel != 6 else Global.scaling

func updateControls() -> void:
	for i in CONTROLS_ARRAY:
		var val = assign_value(i)
		CONTROLS_VALUES[i] = val
	
	for i in 7:
		get_node('Label' + str(i)).text = CONTROLS_VALUES[CONTROLS_ARRAY[i]]

func saveOptions() -> void:
	Global.controls = CONTROLS_VALUES
	
	Global.toSaveInfo = {
		'SoundVol': Global.soundBar,
		'MusicVol': Global.musicBar,
		'Efekty': Global.effects,
		'Scroll': Global.scroll,
		'Quality': Global.quality,
		'Scaling': Global.scaling,
		'Controls': Global.controls,
		'VSync': OS.vsync_enabled,
		'RPC': Global.rpc,
		'Autopause': Global.autopause,
		'Overlay': Global.overlay,
		'Autosave': Global.autosave
	}
	Global.saveInfo(JSON.print(Global.toSaveInfo))

func assign_value(key) -> String:
	var out: String
	for action in InputMap.get_action_list(key):
		if action is InputEventKey:
			out = OS.get_scancode_string(action.scancode)
	return out

func promptRestart() -> void:
	pass
#	popup = popup_node.instance()
#	var prompt = prompt_node.instance()
#	get_parent().add_child(popup)
#	popup.add_child(prompt)
#
#	get_parent().get_tree().paused = true

func freeRestartPrompt() -> void:
	screen = 0
	sel = 1
	$enter_options.play()
