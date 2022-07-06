extends Area2D

export var move_with_scroll: bool = false

func _process(_delta):
  if move_with_scroll:
    var cam = Global.Mario.get_node_or_null('Camera')
    if position.x >= cam.limit_left and position.x <= cam.limit_right - 320:
      position.x = cam.global_position.x - 320
    if position.x < cam.limit_left:
      position.x = cam.limit_left
    elif position.x > cam.limit_right - 640:
      position.x = cam.limit_right - 640
