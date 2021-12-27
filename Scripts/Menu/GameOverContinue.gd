extends Node

var scene

var sel: int = 0
var counter: float = 0
  
func _ready():
  $no.frame = 1
  
func _process(delta):
  if get_parent().isPaused:
    
    # FADE IN
    
    if get_parent().cm.color.r > 0.355:           # Fade in process
      for spr in get_children():
        if spr is AnimatedSprite or spr is Sprite:
          spr.modulate.a += (1 - spr.modulate.a) * 0.05 * Global.get_delta(delta)
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
    get_parent().get_node('coin').play()
  
  if Input.is_action_just_pressed('ui_left') and sel > 0:
    sel -= 1
    $no.frame = 1
    $no.modulate.a = 1
    get_parent().get_node('coin').play()
  
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
