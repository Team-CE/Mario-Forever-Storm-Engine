tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func get_importer_name():
	return 'libopenmpt.modimporter'

func get_visible_name():
	return 'Tracker Music'

func get_recognized_extensions():
	return [
		'mptm', 'mod', 's3m', 'xm', 'it', '669', 'amf', 'ams', 'c67', 'mmcmp',
		'dbm', 'digi', 'dmf', 'dsm', 'dsym', 'dtm', 'far', 'fmt', 'imf', 'ice',
		'j2b', 'm15', 'mdl', 'med', 'mms', 'mt2', 'mtm', 'mus', 'nst', 'okt',
		'plm', 'psm', 'pt36', 'ptm', 'sfx', 'sfx2', 'st26', 'stk', 'stm', 'stx',
		'stp', 'symmod', 'ult', 'wow', 'gdm', 'mo3', 'oxm', 'umx', 'xpk', 'ppm'
	]

func get_save_extension():
	return 'res'

func get_resource_type():
	return 'Resource'

func get_preset_count():
	return Presets.size()
	
func get_preset_name(preset):
	match preset:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"
			
func get_import_options(preset):
	match preset:
		Presets.DEFAULT:
			return [{
							"name": "interpolation",
							"default_value": 0,
							"property_hint": PROPERTY_HINT_ENUM,
							"hint_string": "Default,Nothing,Linear,Cubic:4,Sinc:8"
						}, {
							"name": "loop",
							"default_value": true,
						}, {
							"name": "volume_offset",
							"default_value": 0.0,
						}
			]
		_:
			return []

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
		return err
	
	var buffer = file.get_buffer(file.get_len())
	file.close()
	var resource = load('res://addons/libopenmpt_importer/tracker_resource.gd').new()
	resource.data = buffer
	resource.interpolation = options.interpolation
	resource.loop = options.loop
	resource.volume_offset = options.volume_offset
	
	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], resource)
