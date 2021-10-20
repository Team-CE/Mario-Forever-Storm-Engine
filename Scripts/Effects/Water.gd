tool
extends Area2D

func _process(delta):
  var old_scale = $Sprite.scale.y
  if !Input.is_mouse_button_pressed(1) and $Sprite.scale.y != 1:
    $Sprite.scale.y = 1
    $Sprite.region_rect = Rect2(0, 0, 640, old_scale * 17)
    for i in range(int($Sprite.scale.x)):
      var new_sprite = $Sprite
      new_sprite.position.x = 128 * i
      get_parent().add_child(new_sprite)
