extends Node2D

var scene

var sel: int = 0
var counter: float = 0
  
func _ready():
  $no.frame = 1
  
func _process(delta):
  if get_parent().isPaused:
    
    # FADE IN
    
    if modulate.v > 0.355:           # Fade in process
      modulate.a += (1 - modulate.a) * 0.05 * Global.get_delta(delta)
    else:                                         # Fade has been finished
      counter += 0.15 * Global.get_delta(delta)
      var sinalpha = sin(counter) * 0.3 + 0.7
      if sel: # No
        $no.frame = 0
        $no.modulate.a = sinalpha
      else:   # Yes
        $yes.frame = 0
        $yes.modulate.a = sinalpha
    
  if Input.is_action_just_pressed('ui_right') and sel < 1:
    sel += 1
    $yes.frame = 1
    $yes.modulate.a = 1
    get_node('../coin').play()
  
  if Input.is_action_just_pressed('ui_left') and sel > 0:
    sel -= 1
    $no.frame = 1
    $no.modulate.a = 1
    get_node('../coin').play()
  
  if Input.is_action_just_pressed('ui_accept'):
    if sel: # No
      Global.reset_all_values()
      Global.goto_scene(ProjectSettings.get_setting('application/config/main_menu_scene'))
      get_parent().queue_free()
    else:   # Yes
# warning-ignore:return_value_discarded
      Global.reset_all_values()
      get_tree().reload_current_scene()
      get_parent().queue_free()
    if Global.musicBar == -100:
      AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
# warning-ignore:return_value_discarded
    get_parent().get_parent().get_tree().paused = false
