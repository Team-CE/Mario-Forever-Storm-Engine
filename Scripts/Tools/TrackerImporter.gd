extends ResourceFormatLoader
tool

var extensions := PoolStringArray(
	[
		'mptm', 'mod', 's3m', 'xm', 'it', '669', 'amf', 'ams', 'c67', 'dbm',
		'digi', 'dmf', 'dsm', 'dsym', 'dtm', 'far', 'fmt', 'imf', 'ice', 'j2b',
		'm15', 'mdl', 'med', 'mms', 'mt2', 'mtm', 'mus', 'nst', 'okt', 'plm',
		'psm', 'pt36', 'ptm', 'sfx', 'sfx2', 'st26', 'stk', 'stm', 'stx', 'stp',
		'symmod', 'ult', 'wow', 'gdm', 'mo3', 'oxm', 'umx', 'xpk', 'ppm', 'mmcmp'
	])

func get_recognized_extensions():
	return extensions

func get_resource_type(path):
	var ext = path.get_extension().to_lower()
	if ext in extensions:
		print_debug(ext)
		return 'Resource'
	return ''
	
func handles_type(typename):
	return typename == "Resource"
