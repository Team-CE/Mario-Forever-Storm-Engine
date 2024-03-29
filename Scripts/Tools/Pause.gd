extends Node2D

var sel: int = 0
var selLimit: int = 5
var counter: float = 1
var can_restart: bool = true
var is_cutscene: bool = false

var is_dead: bool = false

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar) - 6)
	if Global.lives == 0 || !is_instance_valid(Global.Mario) || (is_instance_valid(Global.Mario) && !Global.Mario.controls_enabled) || Global.current_scene.get_class() in 'Map':
		can_restart = false
		$sel1.frame = 2
	if 'sgr_scroll' in Global.current_scene and Global.current_scene.sgr_scroll:
		can_restart = false
	elif Global.current_scene.is_class('Cutscene'):
		is_cutscene = true
		$sel1.animation = 'skip'
		$sel1.frame = 0
	
	is_dead = is_instance_valid(Global.Mario) and Global.Mario.dead

func _physics_process(delta):
	#if Input.is_action_just_pressed('ui_fullscreen'):
	#	OS.window_fullscreen = !OS.window_fullscreen
		
	if get_parent().options: return
	if get_parent().isPaused:
		
		# FADE IN
		
		#if get_node('../Sprite').modulate.v > 0.355:					 # Fade in process
		modulate.a += (1 - modulate.a) * 0.1 * Global.get_delta(delta)
		#else:																				 # Fade has been finished
		counter += 0.15 * Global.get_delta(delta)
		var sinalpha = sin(counter) * 0.3 + 0.7
		get_node('sel' + str(sel)).modulate.a = sinalpha
		
		if !is_cutscene:
			if sel != 1 or (sel == 1 and can_restart): get_node('sel' + str(sel)).frame = 1
			if !can_restart and $sel1.frame != 2: $sel1.frame = 2
		
			$sub.visible = sel == 1
			if sel == 1:
				if can_restart and !is_dead:
					$sub.animation = 'default'
				elif Global.lives == 0 and is_instance_valid(Global.Mario):
					$sub.animation = 'blocked'
				else:
					$sub.animation = 'empty'
		else:
			get_node('sel' + str(sel)).frame = 1
		
		# CONTROLS
		
		if Input.is_action_just_pressed('ui_down'):
			get_node('sel' + str(sel)).frame = 0
			get_node('sel' + str(sel)).modulate.a = 1
			sel = 0 if sel + 1 > selLimit else sel + 1
			get_node('../choose').play()
		elif Input.is_action_just_pressed('ui_up'):
			get_node('sel' + str(sel)).frame = 0
			get_node('sel' + str(sel)).modulate.a = 1
			sel = selLimit if sel - 1 < 0 else sel - 1
			get_node('../choose').play()
		
		
		if Input.is_action_just_pressed('ui_accept') and counter > 1:
			match sel:
				0:
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
					get_parent().resume()
					get_tree().paused = false
				1:
					if is_cutscene:
						var to_jump
						if 'change_to_scene' in Global.current_scene and Global.current_scene.change_to_scene != '':
							to_jump = Global.current_scene.change_to_scene
						elif 'scene' in Global.current_scene and Global.current_scene.scene != '':
							to_jump = Global.current_scene.scene
						else:
							for i in Global.current_scene.get_tree().get_nodes_in_group('Warp'):
								if 'set_scene_path' in i.additional_options and i.additional_options['set_scene_path'] != '':
									to_jump = i.additional_options['set_scene_path']
									break
						if !to_jump:
							return
						_goto_scene(to_jump, false)
						get_node('../enter').play()
						get_parent().resume()
						get_tree().set_deferred('paused', false)
							
					elif can_restart:
						AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
						if is_dead:
							Global._reset()
						else:
							Global._pll()
						get_node('../enter').play()
						get_parent().resume()
						get_tree().set_deferred('paused', false)
				2:
					get_node('../enter').play()
					get_node('../Options')._pseudo_ready()
					get_parent().options = true
				3:
					_goto_scene(ProjectSettings.get_setting('application/config/save_game_room_scene'))
				4:
					_goto_scene(ProjectSettings.get_setting('application/config/main_menu_scene'))
				5:
					get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
					get_parent().queue_free()
					
			
		if Input.is_action_just_pressed('ui_cancel') and counter > 3:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
			get_parent().resume()
			get_tree().paused = false

	else:
		# FADE OUT
		modulate.a += (0 - modulate.a) * 0.2 * Global.get_delta(delta)

func _goto_scene(scene: String, reset_values: bool = true) -> void:
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), 0, false)
	MusicPlayer.main.stop()
	MusicPlayer.star.stop()
	if reset_values:
		Global.reset_all_values()
	Global.popup.queue_free()
	Global.popup = null
	get_tree().paused = false
	Global.goto_scene(scene)
