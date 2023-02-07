extends ViewportContainer

var filter_enabled = true setget _on_filter_change

onready var vp = $Viewport
onready var RESOLUTION = $Viewport.size
onready var ASPECT_RATIO = RESOLUTION.x / RESOLUTION.y

var current_pixel_scale = 1.0

func _on_filter_change(val):
	filter_enabled = val
	if val == true:
		material = preload('res://Prefabs/ViewportContainer.tres')
		_update_view()
# warning-ignore:return_value_discarded
		if !$'/root'.is_connected('size_changed', self, '_on_window_resized'):
			$'/root'.connect('size_changed', self, '_on_window_resized')
	else:
		if $'/root'.is_connected('size_changed', self, '_on_window_resized'):
# warning-ignore:return_value_discarded
			$'/root'.disconnect('size_changed', self, '_on_window_resized')
		material = null
		_reset_values()

func _on_window_resized():
	_update_view()

func _update_view():
	var window_size = OS.window_size
	if window_size.y == 0 || window_size.x == 0: return
	var window_aspect_radio = window_size.x / window_size.y

	var target_position
	var width
	var height
	if window_aspect_radio < ASPECT_RATIO:
		width = window_size.x
		height = width / ASPECT_RATIO
		target_position = Vector2(0, (window_size.y - height)/2)
	else:
		height = window_size.y
		width = height * ASPECT_RATIO
		target_position = Vector2((window_size.x - width)/2, 0)

	var target_size = Vector2(width, height)
	var target_scale = target_size / RESOLUTION

	rect_position = target_position
	rect_size = target_size
	rect_scale = target_scale
	material.set_shader_param("texture_size", target_size)
	_update_pixel_scale(_calculate_pixel_scale(target_scale))

func _calculate_pixel_scale(scale):
	var pixel_scale = ceil(min(scale.x, scale.y))
	if pixel_scale == 0.0:
		return 1.0
	return pixel_scale

func _update_pixel_scale(new_pixel_scale):
	if current_pixel_scale != new_pixel_scale:
		current_pixel_scale = new_pixel_scale
		material.set_shader_param("pixel_scale", new_pixel_scale)

func _reset_values():
	rect_position = Vector2.ZERO
	rect_size = Vector2(640, 480)
	rect_scale = Vector2.ONE
	#material.set_shader_param("texture_size", rect_size)



# -----------------------------------------------------------------------------



export var main_scene_node_path: NodePath = ''
export var auto_ready: bool = true

func reset():
	auto_ready = true
	main_scene_node_path = ''
	
	for node in vp.get_children():
		if node is Node2D: continue
		node.queue_free()

#func _ready():
#	var root = get_tree().get_root()
#	Global.current_scene = root.get_child(root.get_child_count() - 1)
#
#	#if auto_ready:
#		#Global.current_scene.connect('ready', self, '_on_scene_ready')
#
#	# Move the scene to viewport with shader if one launches it using the F6 key in Godot
#	if Global.current_scene.get_parent() == root:
#		root.call_deferred('remove_child', Global.current_scene)
#		print('delered')

#func _on_scene_ready():
#	print(main_scene_node_path)
#
#	vp.get_node(main_scene_node_path).call_deferred('add_child', Global.current_scene)
#	print('ok')
