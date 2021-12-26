extends Node

var sel: int = 0
var counter: float = 1

func _process(delta):
  if get_parent().isPaused:
    
    # FADE IN
    
    if get_parent().cm.color.r > 0.355:           # Fade in process
      for spr in get_children():
        if spr is AnimatedSprite or spr is Sprite:
          spr.modulate.a += (1 - spr.modulate.a) * 0.1 * Global.get_delta(delta)
    else:                                         # Fade has been finished
      counter += 0.15 * Global.get_delta(delta)
      var sinalpha = sin(counter) * 0.3 + 0.7
      get_node('sel' + str(sel)).modulate.a = sinalpha
    
    get_node('sel' + str(sel)).frame = 1
    
    # CONTROLS
    
    if Input.is_action_just_pressed('ui_down') and sel < 3:
      get_node('sel' + str(sel)).frame = 0
      get_node('sel' + str(sel)).modulate.a = 1
      sel += 1
      get_parent().get_node('choose').play()
    elif Input.is_action_just_pressed('ui_up') and sel > 0:
      get_node('sel' + str(sel)).frame = 0
      get_node('sel' + str(sel)).modulate.a = 1
      sel -= 1
      get_parent().get_node('choose').play()
    
    if Input.is_action_just_pressed('ui_accept') and counter > 1:
      match sel:
        0:
          get_parent().resume()
        1:
          get_tree().change_scene(ProjectSettings.get_setting('application/config/save_game_room_scene'))
          get_parent().resetandfree()
        2:
          get_tree().change_scene(ProjectSettings.get_setting('application/config/main_menu_scene'))
          get_parent().resetandfree()
        3:
          get_tree().quit()
          get_parent().queue_free()
      
      get_parent().get_parent().get_tree().paused = false
      
    if Input.is_action_just_pressed('ui_cancel') and counter > 1:
      get_parent().resume()
      get_parent().get_parent().get_tree().paused = false

  else:
    
    # FADE OUT
    
    for spr in get_children():
      if spr is AnimatedSprite or spr is Sprite:
        spr.modulate.a += (0 - spr.modulate.a) * 0.15 * Global.get_delta(delta)
