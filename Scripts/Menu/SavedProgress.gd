extends Node2D

var selStart = 0
var selLimit = 2
var sel: int = 0
var counter: float = 0
var ready: bool = false

var saved_progress: Dictionary
	
func _ready():
	yield(get_tree(), 'idle_frame')
	# Do not show if the player enters save room after beating some level
	if Global.levelID == 99:
		queue_free()
		Global.levelID = 0
		return

	# Loading saved progress for preview
	#
	# You must have an AnimatedSprite node as a child to SavedProgress scene,
	# named as an icon pack code prefixed with "Level".
	# Animation names should be zero-based level indexes.
	var is_safe: bool = load_data()
	if !is_safe:
		queue_free()
		return

	# Popup initialization
	Global.popup = Global.popup_node.instance()
	GlobalViewport.vp.add_child(Global.popup)
	get_parent().remove_child(self)
	Global.popup.add_child(self)
	get_tree().paused = true
	
	visible = true
	modulate.a = 0
	ready = true
	
func load_data() -> bool:
	if saved_progress.size() > 0:
		print(saved_progress)
	else:
		return false
	if saved_progress and 'state' in saved_progress and 'icon_pack' in saved_progress and 'levelid' in saved_progress:
		if has_node('Level' + saved_progress.icon_pack):
			get_node('Level' + saved_progress.icon_pack).animation = str(saved_progress.levelid)
		else:
			push_warning('Invalid icon pack "' + saved_progress.icon_pack + '", could not open saved progress popup')
			return false
		for i in get_children():
			if 'Level' in i.name and not 'Level' + saved_progress.icon_pack in i.name:
				i.visible = false
		$KtoryMarian.animation = str(saved_progress.state)
		return true
	return false

func _physics_process(delta):
	if !ready:
		return
	if get_parent().isPaused:
		modulate.a += (1 - modulate.a) * 0.1 * Global.get_delta(delta)

		counter += 0.15 * Global.get_delta(delta)
		var sinalpha = sin(counter) * 0.3 + 0.7
		get_node('Text/sel' + str(sel)).frame = 1
		get_node('Text/sel' + str(sel)).modulate.a = sinalpha
		
		if $AnimationPlayer.is_playing():
			return

		if Input.is_action_just_pressed('ui_right'):
			get_node('Text/sel' + str(sel)).frame = 0
			get_node('Text/sel' + str(sel)).modulate.a = 1
			sel = selStart if sel + 1 > selLimit else sel + 1
			get_node('../coin').play()
		elif Input.is_action_just_pressed('ui_left'):
			get_node('Text/sel' + str(sel)).frame = 0
			get_node('Text/sel' + str(sel)).modulate.a = 1
			sel = selLimit if sel - 1 < selStart else sel - 1
			get_node('../coin').play()

		if Input.is_action_just_pressed('ui_cancel'):
			get_tree().paused = false
			get_parent().resume()

		if Input.is_action_just_pressed('ui_accept'):
			match sel:
				0:	 # Yes
					#Global.current_scene.get_node('DiscordRPCSetting').queue_free()
					Global.reset_all_values()
					Global.lives = saved_progress.lives
					Global.score = saved_progress.score
					Global.coins = saved_progress.coins
					Global.state = saved_progress.state
					Global.levelID = saved_progress.levelid
					Global.popup.queue_free()
					Global.popup = null
					Global.goto_scene(saved_progress.scene)
					get_tree().paused = false
				1: # No
					get_tree().paused = false
					get_parent().resume()
				2: # Erase
					get_node('Text/sel' + str(sel)).frame = 0
					get_node('Text/sel' + str(sel)).modulate.a = 1
					selStart = 3
					selLimit = 4
					sel = 3
					$AnimationPlayer.play('ToOptions')
					$'../enter'.play()
					return
				3: # Yes to erase
					Global.save_contents.erase_section('last_saved_progress')
					Global.save_overwrite = true
					get_tree().paused = false
					get_parent().resume()
				4: # No to erase
					get_node('Text/sel' + str(sel)).frame = 0
					get_node('Text/sel' + str(sel)).modulate.a = 1
					selStart = 0
					selLimit = 2
					sel = 0
					$AnimationPlayer.play('FromOptions')
					$'../enter'.play()
	else:
		# FADE OUT
		modulate.a += (0 - modulate.a) * 0.2 * Global.get_delta(delta)
