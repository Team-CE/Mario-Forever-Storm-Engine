extends Node

var scene

var sel: int = 0
var counter: float = 0
  
func _process(delta):
  if get_parent().isPaused:
    
    # FADE IN
    
    if get_parent().cm.color.r > 0.35001:           # Fade in process
      for spr in get_children():
        if spr is AnimatedSprite or spr is Sprite:
          spr.modulate.a += (1 - spr.modulate.a) * 0.05 * Global.get_delta(delta)
    else:                                         # Fade has been finished
      counter += 0.125 * Global.get_delta(delta)
      var sinscale = sin(counter) * 0.25 + 1
      if sel: # No
        $no.scale = Vector2(sinscale, sinscale)
        $yes.scale = Vector2.ONE
      else:   # Yes
        $yes.scale = Vector2(sinscale, sinscale)
        $no.scale = Vector2.ONE
  $ifyou.frame = sel
  
  if Input.is_action_just_pressed('ui_right') and sel < 1:
    sel += 1
    get_parent().get_node('choose').play()
  
  if Input.is_action_just_pressed('ui_left') and sel > 0:
    sel -= 1
    get_parent().get_node('choose').play()
  
  if Input.is_action_just_pressed('ui_accept'):
    if sel: # No
      get_tree().change_scene(ProjectSettings.get_setting('application/config/main_menu_scene'))
      get_parent().resetandfree()
    else:   # Yes
      get_tree().reload_current_scene()
      get_parent().resetandfree()
    if Global.musicBar == -100:
      MusicPlayer.volume_db = -1000
# warning-ignore:return_value_discarded
    get_parent().get_parent().get_tree().paused = false
    get_parent().get_parent().get_node('WorldEnvironment').environment.dof_blur_near_enabled = false
