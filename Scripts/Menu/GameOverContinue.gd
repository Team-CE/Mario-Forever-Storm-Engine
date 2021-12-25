extends Control

var fading_out: bool = false
var fading_in: bool = true
var circle_size = 0
var scene

var controls_enabled: bool = false
var sel: int = 0
var counter: float = 0

func _ready():
  #yield(get_tree().create_timer( 1.2 ), 'timeout')
  pass
  
func _process(delta):
  if controls_enabled:
    controls(delta)
  
  if fading_out:
    circle_size -= 0.012 * Global.get_delta(delta)
    $Transition.visible = true
    $Transition.material.set_shader_param('circle_size', circle_size)
  else:
    $Transition.visible = false
  
  if fading_in:
    circle_size += 0.012 * Global.get_delta(delta)
    $Transition.visible = true
    $Transition.material.set_shader_param('circle_size', circle_size)
    if circle_size > 0.623:
      $Transition.visible = false
      circle_size = 0.623
      fading_in = false
      controls_enabled = true

func controls(delta):
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
    $Select.play()
  
  if Input.is_action_just_pressed('ui_left') and sel > 0:
    sel -= 1
    $Select.play()
  
  if Input.is_action_just_pressed('ui_accept'):
    if sel: # No
      scene = ProjectSettings.get_setting('application/run/main_scene')
    else:   # Yes
      scene = Global.gameoverLevel
    controls_enabled = false
    fading_out = true
    yield(get_tree().create_timer( 1.2 ), 'timeout')
    fading_out = false
    if Global.musicBar == -100:
      MusicPlayer.volume_db = -1000
# warning-ignore:return_value_discarded
    get_tree().change_scene(scene)
