func _process_camera(owner, delta: float) -> void:
  if !Global.current_scene.stopped or Global.current_scene.fading_out:
    return

  var cam = owner.get_node('Camera')
  if Input.is_action_pressed('mario_right'):
    cam.global_position.x += 5 + (int(Input.is_action_pressed('mario_fire')) * 5) * Global.get_delta(delta)

  if Input.is_action_pressed('mario_left'):
    cam.global_position.x -= 5 - (int(Input.is_action_pressed('mario_fire')) * -5) * Global.get_delta(delta)

  if cam.global_position.x < 320:
    cam.global_position.x = 320

  if cam.global_position.x > cam.limit_right - 320:
    cam.global_position.x = cam.limit_right - 320
