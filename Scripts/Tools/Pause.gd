extends Node

var sel: int = 0
var counter: float = 1
var scene
var can_restart: bool = true

func _ready():
  if Global.musicBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5) - 6)
  if Global.musicBar == -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
  if Global.lives == 0 || !is_instance_valid(Global.Mario) || (is_instance_valid(Global.Mario) && !Global.Mario.controls_enabled):
    can_restart = false
    $sel1.frame = 2
  if 'sgr_scroll' in get_node('../../') and get_node_or_null('../../').sgr_scroll:
    can_restart = false

func _process(delta):
  if get_parent().isPaused:
    
    # FADE IN
    
    if get_node('../Sprite').modulate.v > 0.355:           # Fade in process
      for spr in get_children():
        if spr is AnimatedSprite or spr is Sprite:
          spr.modulate.a += (1 - spr.modulate.a) * 0.1 * Global.get_delta(delta)
    else:                                         # Fade has been finished
      counter += 0.15 * Global.get_delta(delta)
      var sinalpha = sin(counter) * 0.3 + 0.7
      get_node('sel' + str(sel)).modulate.a = sinalpha
    
    if sel != 1 or (sel == 1 and can_restart): get_node('sel' + str(sel)).frame = 1
    
    # CONTROLS
    
    if Input.is_action_just_pressed('ui_down') and sel < 4:
      get_node('sel' + str(sel)).frame = 0
      get_node('sel' + str(sel)).modulate.a = 1
      sel += 1
      get_node('../choose').play()
    elif Input.is_action_just_pressed('ui_up') and sel > 0:
      get_node('sel' + str(sel)).frame = 0
      get_node('sel' + str(sel)).modulate.a = 1
      sel -= 1
      get_node('../choose').play()
    
    if !can_restart and $sel1.frame != 2: $sel1.frame = 2
    
    if Input.is_action_just_pressed('ui_accept') and counter > 0.15:
      match sel:
        0:
          if Global.musicBar > -100:
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
          if Global.musicBar == -100:
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
          get_parent().resume()
        1:
          if !can_restart: return
          if Global.musicBar > -100:
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
          if Global.musicBar == -100:
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
          if is_instance_valid(Global.Mario) and Global.Mario.dead:
            Global._reset()
          else:
            Global._pll()
          get_parent().resume()
        2:
          scene = ProjectSettings.get_setting('application/config/sgr_scene')
          AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), 0, false)
          var error = get_tree().change_scene(scene)
          if error: printerr('[CE ERROR]: Could not load SGR scene')
          MusicPlayer.get_node('Main').stop()
          MusicPlayer.get_node('Star').stop()
          Global.reset_all_values()
          get_parent().queue_free()
        3:
          scene = ProjectSettings.get_setting('application/config/main_menu_scene')
          AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), 0, false)
          var error = get_tree().change_scene(scene)
          if error: printerr('[CE ERROR]: Could not load Main Menu scene')
          MusicPlayer.get_node('Main').stop()
          MusicPlayer.get_node('Star').stop()
          Global.reset_all_values()
          get_parent().queue_free()
        4:
          get_tree().quit()
          get_parent().queue_free()
      
      get_parent().get_parent().get_tree().paused = false
      
    if Input.is_action_just_pressed('ui_cancel') and counter > 1:
      if Global.musicBar > -100:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
      get_parent().resume()
      get_parent().get_parent().get_tree().paused = false

  else:
    
    # FADE OUT
    
    for spr in get_children():
      if spr is AnimatedSprite or spr is Sprite:
        spr.modulate.a += (0 - spr.modulate.a) * 0.15 * Global.get_delta(delta)
