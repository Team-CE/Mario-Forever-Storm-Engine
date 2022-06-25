extends Control

const CONTROLS_ARRAY = [
  'mario_up',
  'mario_crouch',
  'mario_left',
  'mario_right',
  'mario_jump',
  'mario_fire'
]
const CONTROLS_VALUES: Dictionary = {}

export var music: Resource            #MENU Music
export var music_credits: Resource    #CREDITS Music

var sel = 0
var screen = 0
var selLimit
var screen_changed = 0

var fading_in = true
var fading_out = false
var circle_size = 0

var pos_y: float
var force_pos = true

onready var controls_enabled: bool = false
onready var controls_changing: bool = false

func _ready() -> void:
  pos_y = 359
  $Transition.material.set_shader_param('circle_size', circle_size)
  
  $fadeout.play()
  yield(get_tree().create_timer( 1.2 ), 'timeout')
  if !Global.saveFileExists:
    saveOptions()
  MusicPlayer.get_node('Main').stream = music
  MusicPlayer.get_node('Main').play()
  if Global.musicBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
  if Global.musicBar == -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
  if Global.soundBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), round(Global.soundBar / 5))
  if Global.soundBar == -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), -1000)
  
  updateControls()
  
func _process(delta) -> void:
  if controls_enabled:
    controls()
  
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
  
  if (not force_pos):
    $S_Start.position.y += (pos_y - $S_Start.position.y) * 0.4 * Global.get_delta(delta)
  else:
    $S_Start.position.y = pos_y # Used to fix cursor position between transitions
    force_pos = false
  if (screen_changed != screen):
    screen_changed = screen
    force_pos = true
        
  var base_y = screen * 480
  $S_Start/Camera2D.limit_top = base_y
  $S_Start/Camera2D.limit_bottom = base_y + 480
    
  match screen:
    0:
      pos_y = 359 + (29 * sel)
      $S_Start.position.x = 248
      selLimit = 2
      
    1:
      pos_y = 534 + (37.5 * sel)
      $S_Start.position.x = 208
      selLimit = 9
      updateOptions()
      $Credits.hide()
    2:
      pos_y = 987 + (64 * sel) if sel < 7 else 1415
      $S_Start.position.x = 172
      selLimit = 7
    3:
      pos_y = 1920 + 216
      $S_Start.position.x = 240
      selLimit = 0
      $Credits.position.y -= 1 * Global.get_delta(delta)
      $Credits.show()
    
func controls() -> void:
  if Input.is_action_just_pressed('ui_down') and sel < selLimit:
    sel += 1
    if Global.effects:
      var effect = MarioHeadEffect.new($S_Start.position)
      add_child(effect)
    $select_main.play()
  elif Input.is_action_just_pressed('ui_up') and sel > 0:
    sel -= 1
    if Global.effects:
      var effect = MarioHeadEffect.new($S_Start.position)
      add_child(effect)
    $select_main.play()
  
  match screen:
    0:    # _____ MAIN _____
      if Input.is_action_just_pressed('ui_accept'):
        match sel:
          0:
            controls_enabled = false
            if !Global.saveFileExists:
              saveOptions()
            $letsgo.play()
            MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 5.0)
            yield(get_tree().create_timer( 2.5 ), 'timeout')
            $fadeout.play()
            fading_out = true
            yield(get_tree().create_timer( 1.2 ), 'timeout')
            fading_out = false
            if Global.musicBar == -100:
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
# warning-ignore:return_value_discarded
            get_tree().change_scene(ProjectSettings.get_setting('application/config/sgr_scene'))
          1:
            screen += 1
            sel = 0
            $enter_options.play()
          2:
            controls_enabled = false
            $enter_options.play()
            MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 3.0)
            yield(get_tree().create_timer( 1 ), 'timeout')
            fading_out = true
            yield(get_tree().create_timer( 1.4 ), 'timeout')
            get_tree().quit()
            
    1:    # _____ OPTIONS _____
      if Input.is_action_just_pressed('ui_accept'):
        match sel:
          4:
            screen = 2
            sel = 0
            $enter_options.play()
          8:
            screen = 3
            sel = 0
            $enter_options.play()
            $Credits.position.y = 1920 + $Credits.texture.get_height() / 2
            MusicPlayer.get_node('Main').stream = music_credits
            MusicPlayer.get_node('Main').play()
          9:
            screen = 0
            sel = 1
            $enter_options.play()
            saveOptions()
            if Global.restartNeeded:
              Global.restartNeeded = false
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
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
              $tick.play()
          2:
            if !Global.effects:
              Global.effects = true
              $change.play()
          3:
            if Global.scroll < 2:
              Global.scroll += 2
              $change.play()
          5:
            if Global.quality < 2:
              Global.quality += 1
              $change.play()
          6:
            if !Global.scaling:
              Global.scaling = true
              $change.play()
              saveOptions()
              yield(get_tree(), 'idle_frame')
              updateControls()
              
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
                AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
              if Global.musicBar == -100:
                AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
              $tick.play()
          2:
            if Global.effects:
              Global.effects = false
              $change.play()
          3:
            if Global.scroll > 0:
              Global.scroll -= 2
              $change.play()
          5:
            if Global.quality > 0:
              Global.quality -= 1
              $change.play()
          6:
            if Global.scaling:
              Global.scaling = false
              $change.play()
              saveOptions()
      elif Input.is_action_just_pressed('ui_cancel'):
        screen = 0
        sel = 1
        updateControls()
        saveOptions()
    2:    # _____ CONTROLS _____
      if Input.is_action_just_pressed('ui_accept') and sel < 6:
        get_node('Label' + str(sel)).text = 'PRESS A KEY TO ASSIGN'
        controls_changing = true
        controls_enabled = false
        get_tree().set_input_as_handled()
      
      if Input.is_action_just_pressed('ui_accept') and sel == 6:
        InputMap.load_from_globals()
        updateControls()
        $enter_options.play()
      if (
        Input.is_action_just_pressed('ui_cancel') or
        Input.is_action_just_pressed('ui_accept') and
        sel == 7
      ) and not controls_changing:
        screen = 1
        sel = 4
        controls_changing = false
        controls_enabled = true
        updateControls()
        saveOptions()
    3:    # _____ CREDITS _____
      if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept'):
        screen = 1
        sel = 8
        MusicPlayer.get_node('Main').stream = music
        MusicPlayer.get_node('Main').play()

func _input(event) -> void:
  if event is InputEventKey and event.pressed and controls_changing:
    if not event.is_action('ui_cancel'):
      var scancode = OS.get_scancode_string(event.scancode)
      get_node('Label' + str(sel)).text = scancode
      for old_event in InputMap.get_action_list(CONTROLS_ARRAY[sel]):
        InputMap.action_erase_event(CONTROLS_ARRAY[sel], old_event)
      InputMap.action_add_event(CONTROLS_ARRAY[sel], event)
    else:
      updateControls()
    controls_changing = false
    controls_enabled = true
  
func updateOptions() -> void:
  $Buttons/SoundBar.frame = 10 + (Global.soundBar / 10)
  $Buttons/MusicBar.frame = 10 + (Global.musicBar / 10)
  $Buttons/Effects.frame = Global.effects
  $Buttons/Scroll.frame = Global.scroll
  $Buttons/Quality.frame = Global.quality
  $Buttons/Scaling.frame = Global.scaling
  $Buttons/Restart.visible = Global.restartNeeded

func updateControls() -> void:
  for i in CONTROLS_ARRAY:
    var val = assign_value(i)
    CONTROLS_VALUES[i] = val
  
  for i in 6:
    get_node('Label' + str(i)).text = CONTROLS_VALUES[CONTROLS_ARRAY[i]]

func saveOptions() -> void:
  Global.controls = CONTROLS_VALUES
  
  Global.toSaveInfo = {
    'SoundVol': Global.soundBar,
    'MusicVol': Global.musicBar,
    'Efekty': Global.effects,
    'Scroll': Global.scroll,
    'Quality': Global.quality,
    'Scaling': Global.scaling,
    'Controls': Global.controls
  }
  Global.saveInfo(JSON.print(Global.toSaveInfo))

func assign_value(key) -> String:
  var out: String
  for action in InputMap.get_action_list(key):
    if action is InputEventKey:
      out = OS.get_scancode_string(action.scancode)
  return out
