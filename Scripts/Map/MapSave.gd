extends Node

onready var progress: Dictionary = {
	'lives': 4,
	'score': 0,
	'coins': 0,
	'state': 0,
	'levelid': 0,
	'scene': Global.current_scene.filename,
	'icon_pack': ''
	}
export var save_key:String = ''
export var icon_pack:String = ''
export var save_collectibles: bool = false

func _ready():
	assert(save_key != '', 'save_key must not be empty.')
	assert(icon_pack != '', 'icon_pack must not be empty.')
	if Global.levelID > 0 or Global.save_overwrite:
		var lvl = load_config()
		save_config(lvl)
	
#func _process(delta):
#	pass

func load_config() -> int:
	var config = Global.save_contents

	if !(config is ConfigFile) or config == null:
		push_error('WTF save is null')
		return 0

	if config.has_section('last_saved_progress') and config.has_section_key('last_saved_progress', 'data'):
		progress = config.get_value('last_saved_progress', 'data')

	if config.has_section('map_save') and config.has_section_key('map_save', save_key):
		var saved_levelid: int = config.get_value('map_save', save_key)
		
		if saved_levelid < 10:
			return saved_levelid
		
	return 0

func save_config(lvl):
	var config = Global.save_contents
	var password = OS.get_unique_id() #Works only on user's pc
	
	var level_to_save: int = Global.levelID if Global.levelID > lvl else lvl
	
	config.set_value('map_save', save_key, level_to_save)
	
	if save_collectibles:
		if Global.collectible_saved:
			if Global.collectibles_array.size() < 10: # defaulting the variable if it doesn't exist in save file
				Global.collectibles_array.resize(10)
				Global.collectibles_array.fill(false)
			for i in range(len(Global.collectibles_array)): # without (range + len) it just returns False
				if i == Global.levelID - 1:
					Global.collectibles_array[i] = true
			Global.collectible_saved = false
		config.set_value('green_stars', 'saved', Global.collectibles_array)
	else:
		Global.collectibles = 0

	if Global.autosave and !Global.save_overwrite:
		var progress_dict: Dictionary = {
		'lives': Global.lives,
		'score': Global.score,
		'coins': Global.coins,
		'state': Global.state,
		'levelid': Global.levelID,
		'scene': Global.current_scene.filename,
		'icon_pack': icon_pack
		}
		config.set_value('last_saved_progress', 'data', progress_dict if Global.score > 0 else progress)

	Global.save_overwrite = false
	
	var err = config.save_encrypted_pass('user://save.cloudsav', password)
	config.save('user://save_test.cloudsav') # FOR TESTING PURPOSES
	print('GAME SAVED: levels: ', level_to_save, ', stars: ', Global.collectibles_array)
	
	if err:
		OS.alert('Saving failed, ERROR CODE ' + str(err))
		return
