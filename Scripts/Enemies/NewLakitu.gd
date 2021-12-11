extends Node

var camera = Global.Mario.get_node('Camera')
var throw_script
var throw_delay

func _ready() -> void:
  yield(get_tree().create_timer(7.0), 'timeout')
  var lakitu = load('res://Objects/Enemies/Lakito.tscn').instance()
  lakitu.vars['throw_script'] = throw_script
  lakitu.vars['throw_delay'] = throw_delay
  lakitu.position = Vector2(camera.global_position.x + 520, camera.limit_top + 72 + rand_range(-16, 16))
  get_parent().add_child(lakitu)
