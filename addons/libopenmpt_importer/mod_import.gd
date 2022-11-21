tool
extends EditorPlugin

var import_plugin
var export_plugin

func _enter_tree():
	add_custom_type('TrackerAudio', 'Resource', preload('res://addons/libopenmpt_importer/tracker_resource.gd'), load('res://addons/libopenmpt_importer/icon.png'))
	
	import_plugin = preload("import_plugin.gd").new()
#	export_plugin = TrackerAudioExporter.new()
	
	add_import_plugin(import_plugin)
#	add_export_plugin(export_plugin)

func _exit_tree():
	remove_custom_type('TrackerAudio')
	
	remove_import_plugin(import_plugin)
#	remove_export_plugin(export_plugin)
	
	import_plugin = null
#	export_plugin = null


#class TrackerAudioExporter extends EditorExportPlugin:
#
#	var output_root_dir
#
#	func _export_begin(_features: PoolStringArray, _is_debug: bool, path: String, _flags: int):
#		output_root_dir = path.get_base_dir()
#
#	func _export_file(path, _type, _features):
#		if path.get_extension() in MusicPlayer.TRACKER_EXTENSIONS:
#			_export_file_our_way(path)
#
#	func _export_file_our_way(path):
#		print('Included file: ' + path)
#		skip()
#
#		var rfile = File.new()
#		rfile.open(path, File.READ)
#		var buffer = rfile.get_buffer(rfile.get_len())
#		rfile.close()
#
#		var output_path = output_root_dir.plus_file(path.trim_prefix("res://"))
#
#		var wfile = File.new()
#		wfile.open(output_path, File.WRITE)
#		wfile.store_buffer(buffer)
#		wfile.close()
