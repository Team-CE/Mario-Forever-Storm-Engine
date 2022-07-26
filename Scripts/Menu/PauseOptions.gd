extends Node2D

var sel: int = 0
var counter: float = 1

func _pseudo_ready():
  $AnimationPlayer.play('ToOptions')
  sel = 0
  counter = 0
  updateOptions()
  for i in get_children():
    if 'sel' in i.name:
      i.frame = 0
      i.modulate.a = 1

func _process(delta):
  if $AnimationPlayer.is_playing():
    get_node('../Pause').position = position - Vector2(640, 0)
    
  if !get_parent().options: return
  
  # Text blinking
  counter += 0.15 * Global.get_delta(delta)
  var sinalpha = sin(counter) * 0.3 + 0.7
  get_node('sel' + str(sel)).modulate.a = sinalpha
  # Text selection
  get_node('sel' + str(sel)).frame = 1
  # VSync Subtitle
  $VSyncNote.visible = sel == 3
  
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
  
  if Input.is_action_just_pressed('ui_accept') and counter > 0.15:
    if sel == 4:
      $AnimationPlayer.play('FromOptions')
      get_node('../enter').play()
      get_parent().options = false
  if Input.is_action_just_pressed('ui_right'):
    match sel:
      0:
        if Global.soundBar < 0:
          Global.soundBar += 10
          AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), round(Global.soundBar / 5))
          $tick.play()
      1:
        if Global.musicBar < 0:
          Global.musicBar += 10
          AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5) - 6)
          $tick.play()
      2:
        if !Global.autopause:
          Global.autopause = true
          $change.play()
      3:
        if !OS.vsync_enabled:
          OS.vsync_enabled = true
          $change.play()
    updateOptions()
          
  elif Input.is_action_just_pressed('ui_left'):
    match sel:
      0:
        if Global.soundBar > -100:
          Global.soundBar -= 10
          AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), round(Global.soundBar / 5))
          $tick.play()
        if Global.soundBar == -100:
          AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), -1000)
      1:
        if Global.musicBar > -100:
          Global.musicBar -= 10
          if Global.musicBar > -100:
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5) - 6)
          if Global.musicBar == -100:
            AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
          $tick.play()
      2:
        if Global.autopause:
          Global.autopause = false
          $change.play()
      3:
        if OS.vsync_enabled:
          OS.vsync_enabled = false
          $change.play()
    updateOptions()
    
  if Input.is_action_just_pressed('ui_cancel') and counter > 1:
    $AnimationPlayer.play('FromOptions')
    saveOptions()
    get_parent().options = false


func updateOptions() -> void:
  $SoundBar.frame = 10 + (Global.soundBar / 10)
  $MusicBar.frame = 10 + (Global.musicBar / 10)
  $AutoPause.frame = Global.autopause
  $VSync.frame = OS.vsync_enabled
  
func saveOptions() -> void:
  Global.toSaveInfo = {
    'SoundVol': Global.soundBar,
    'MusicVol': Global.musicBar,
    'Efekty': Global.effects,
    'Scroll': Global.scroll,
    'Quality': Global.quality,
    'Scaling': Global.scaling,
    'Controls': Global.controls,
    'VSync': OS.vsync_enabled,
    'Autopause': Global.autopause
  }
  Global.saveInfo(JSON.print(Global.toSaveInfo))
