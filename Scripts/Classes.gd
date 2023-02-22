extends Node
# This class will autoload scripts and scenes named "preload" upon loading the game

# References to scripts & scenes
var scripts: Array
var scenes: Array

func _init():
	var autoload_script_list: Array = get_files("res://Games/", "preload.gd")
	if !autoload_script_list.empty():
		for i in autoload_script_list:
			var instance = load(i).new()
			scripts.append(instance)
			add_child(instance)
	
	var autoload_scene_list: Array = get_files("res://Games/", "preload.tscn")
	if !autoload_scene_list.empty():
		for i in autoload_scene_list:
			var instance = load(i).instance()
			scenes.append(instance)
			add_child(instance)

func get_files(path: String, file := "", files := []) -> Array:
	var dir := Directory.new()
	if !dir || dir.open(path) != OK:
		printerr('[Classes] Could not open path %s' % path)
		return []
	
# warning-ignore:return_value_discarded
	dir.list_dir_begin(true, true)
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			files = get_files(dir.get_current_dir().plus_file(file_name), file, files)
		else:
			if file != "" && file_name.get_file() != file:
				file_name = dir.get_next()
				continue
			
			files.append(dir.get_current_dir().plus_file(file_name))
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files
