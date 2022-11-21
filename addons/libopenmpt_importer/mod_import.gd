tool
extends EditorPlugin

var import_plugin

func _enter_tree():
	add_custom_type('TrackerAudio', 'Resource', preload('res://addons/libopenmpt_importer/tracker_resource.gd'), load('res://addons/libopenmpt_importer/icon.png'))
	import_plugin = preload("import_plugin.gd").new()
	add_import_plugin(import_plugin)

func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null
