extends Control

var Sounds: Array = []

func _ready():
	Sounds.append_array(get_all_in_folder("res://Sounds/"))
	for i in Sounds:
		var copy = i
		copy.erase(0,i.find_last('/')+1)
		$OptionButton.add_item(copy)
	if !Sounds.empty():
		$Test.stream = load(Sounds[0])
	yield(Global.get_tree(), 'idle_frame')
	#AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), 0, true)
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index('CompositedSounds'), -8)

func get_all_in_folder(path) -> Array:
	var dir = Directory.new()
	var result: Array = []
	dir.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() && (file_name != '.' && file_name != '..'):
			result.append_array(get_all_in_folder(path + file_name +'/'))
		elif file_name != '.' && file_name != '..' && !('.import' in file_name) && !('.wavold' in file_name):
			result.append(path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func _on_Button_pressed():
	$Test.pitch_scale = 1
	for i in range($CenterContainer/VBoxContainer/Times.value + 1):
		$CenterContainer/VBoxContainer/Label.text = str(i) 
		$Test.play()
		yield(get_tree().create_timer($CenterContainer/VBoxContainer/Delay.value), "timeout")
		$Test.pitch_scale += $CenterContainer/VBoxContainer/Pitch.value
	$CenterContainer/VBoxContainer/Label.text = '0'

func _on_OptionButton_item_selected(index):
	$Test.stream = load(Sounds[index])
