extends ViewportContainer

var filter_enabled = true setget _on_filter_change

onready var RESOLUTION = $Viewport.size
onready var ASPECT_RATIO = RESOLUTION.x / RESOLUTION.y

var current_pixel_scale = 1.0

func _on_filter_change(val):
	filter_enabled = val
	if val == true:
		material = preload('res://Prefabs/ViewportContainer.tres')
		_update_view()
# warning-ignore:return_value_discarded
		if !get_node('/root').is_connected('size_changed', self, '_on_window_resized'):
			get_node('/root').connect('size_changed', self, '_on_window_resized')
	else:
		if get_node('/root').is_connected('size_changed', self, '_on_window_resized'):
# warning-ignore:return_value_discarded
			get_node('/root').disconnect('size_changed', self, '_on_window_resized')
		material = null
		_reset_values()

func _on_window_resized():
	_update_view()

func _update_view():
	var window_size = OS.window_size
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
