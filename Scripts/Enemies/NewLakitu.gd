extends Node

var camera = Global.Mario.get_node('Camera')

func _ready():
  yield(get_tree().create_timer(7.0), 'timeout')
  var lakitu = load('res://Objects/Enemies/Lakito.tscn').instance()
  lakitu.position = Vector2(camera.global_position.x + 520, camera.limit_top + 72 + rand_range(-16, 16))
  get_parent().add_child(lakitu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
