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
export var credits_scene: String

var sel = 0
var screen = 0
var selLimit
var screen_changed = 0
const popup_node = preload('res://Objects/Tools/PopupMenu.tscn')
const prompt_node = preload('res://Objects/Tools/PopupMenu/RestartPrompt.tscn')
var popup: CanvasLayer = null

var fading_in = true
var fading_out = false
onready var circle_size = 0

var pos_y: float
var force_pos = true

onready var controls_enabled: bool = false
onready var controls_changing: bool = false
onready var assigned: bool = false

func _ready() -> void:
  pos_y = 359
  $Transition.material.set_shader_param('circle_size', circle_size)
  
  $fadeout.play()
  yield(get_tree().create_timer( 1.2 ), 'timeout')
  if !Global.saveFileExists:
    saveOptions()
  MusicPlayer.get_node('Main').stream = music
  MusicPlayer.get_node('Main').play()
  MusicPlayer.play_on_pause()
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
  
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  
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
      pos_y = 518 + (37.5 * sel)
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
    
func onMenuCursorUpdate() -> void:
  #if Global.effects:
  #  var effect = MarioHeadEffect.new($S_Start.position)
  #  add_child(effect)
# warning-ignore:standalone_ternary
  $select_main.play() if screen < 2 else $select_controls.play()
  if screen == 1: updateNotes()
    
func controls() -> void:
  if Input.is_action_just_pressed('ui_down'):
    sel = 0 if sel + 1 > selLimit else sel + 1
    onMenuCursorUpdate()
  elif Input.is_action_just_pressed('ui_up'):
    sel = selLimit if sel - 1 < 0 else sel - 1
    onMenuCursorUpdate()
  
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
            var fadeout = $fadeout.duplicate()
            get_node('/root').add_child(fadeout)
            fadeout.play()
            fading_out = true
            yield(get_tree().create_timer( 1.2 ), 'timeout')
            fading_out = false
            Global.goto_scene(ProjectSettings.get_setting('application/config/sgr_scene'))
          1:
            screen += 1
            sel = 0
            $enter_options.play()
            updateNotes()
          2:
            controls_enabled = false
            $enter_options.play()
            MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 3.0)
            yield(get_tree().create_timer( 1 ), 'timeout')
            fading_out = true
            yield(get_tree().create_timer( 1.2 ), 'timeout')
            get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
            
    1:    # _____ OPTIONS _____
      if Input.is_action_just_pressed('ui_accept'):
        match sel:
          4:
            screen = 2
            sel = 0
            $enter_options.play()
          8:
            $enter_options.play()
            if credits_scene:
              Global.goto_scene(credits_scene)
            else:
              screen = 3
              sel = 0
              $Credits.position.y = 1920 + $Credits.texture.get_height() / 2
              MusicPlayer.get_node('Main').stream = music_credits
              MusicPlayer.get_node('Main').play()
          9:
            $enter_options.play()
            saveOptions()
            if Global.restartNeeded:
              Global.restartNeeded = false
              promptRestart()
            else:
              screen = 0
              sel = 1
      if Input.is_action_just_pressed('ui_right'):
        match sel:
          0:
            if Global.soundBar < 0.99:
              Global.soundBar += 0.1
              if is_nan(linear2db(Global.soundBar)): Global.soundBar = 1.0
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear2db(Global.soundBar))
              $tick.play()
              print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Sounds')))
          1:
            if Global.musicBar < 0.99:
              Global.musicBar += 0.1
              if is_nan(linear2db(Global.musicBar)): Global.musicBar = 1.0
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
              $tick.play()
              print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')))
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
            if Global.scaling < 1:
              Global.scaling += 1
              $change.play()
              saveOptions()
              yield(get_tree(), 'idle_frame')
              updateNotes()
          7:
            if !OS.vsync_enabled:
              OS.vsync_enabled = true
              $change.play()
              
      elif Input.is_action_just_pressed('ui_left'):
        match sel:
          0:
            if Global.soundBar > 0.0001:
              Global.soundBar -= 0.1
              if is_nan(linear2db(Global.soundBar)): Global.soundBar = 0
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear2db(Global.soundBar))
              $tick.play()
              print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Sounds')))
          1:
            if Global.musicBar > 0.0001:
              Global.musicBar -= 0.1
              if is_nan(linear2db(Global.musicBar)): Global.musicBar = 0
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
              $tick.play()
              print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')))
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
            if Global.scaling > 0:
              Global.scaling -= 1
              $change.play()
              saveOptions()
              updateNotes()
          7:
            if OS.vsync_enabled:
              OS.vsync_enabled = false
              $change.play()
      elif Input.is_action_just_pressed('ui_cancel'):
        screen = 0
        sel = 1
        $enter_options.play()
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
        $enter_options.play()
        updateControls()
        saveOptions()
    3:    # _____ CREDITS _____
      if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept'):
        screen = 1
        sel = 8
        MusicPlayer.get_node('Main').stream = music
        MusicPlayer.get_node('Main').play()

func _input(event) -> void:
  if event is InputEventKey and event.pressed and controls_changing and not event.echo:
    if not event.is_action('ui_cancel'):
      var scancode = OS.get_scancode_string(event.scancode)
      get_node('Label' + str(sel)).text = scancode
      for old_event in InputMap.get_action_list(CONTROLS_ARRAY[sel]):
        InputMap.action_erase_event(CONTROLS_ARRAY[sel], old_event)
      InputMap.action_add_event(CONTROLS_ARRAY[sel], event)
      $select_main.play()
    else:
      updateControls()
    assigned = true
  if event is InputEventKey and not event.pressed and controls_changing and assigned:
    controls_changing = false
    controls_enabled = true
    assigned = false
  
func updateOptions() -> void:
  $Buttons/SoundBar.frame = round(Global.soundBar * 10.0)
  $Buttons/MusicBar.frame = round(Global.musicBar * 10.0)
  $Buttons/Effects.frame = Global.effects
  $Buttons/Scroll.frame = Global.scroll
  $Buttons/Quality.frame = Global.quality
  $Buttons/Scaling.frame = Global.scaling
  $Buttons/VSync.frame = OS.vsync_enabled

func updateNotes() -> void:
  $Buttons/EffectsNote.visible = sel == 2
  $Buttons/ControlsNote.visible = sel == 4
  $Buttons/QualityNote.visible = sel == 5
  $Buttons/ScalingNote.visible = sel == 6
  $Buttons/ScalingNote.frame = Global.scaling
  $Buttons/VSyncNote.visible = sel == 7

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
    'Controls': Global.controls,
    'VSync': OS.vsync_enabled,
    'Autopause': Global.autopause
  }
  Global.saveInfo(JSON.print(Global.toSaveInfo))

func assign_value(key) -> String:
  var out: String
  for action in InputMap.get_action_list(key):
    if action is InputEventKey:
      out = OS.get_scancode_string(action.scancode)
  return out

func promptRestart() -> void:
  popup = popup_node.instance()
  var prompt = prompt_node.instance()
  get_parent().add_child(popup)
  popup.add_child(prompt)
  
  get_parent().get_tree().paused = true

func freeRestartPrompt() -> void:
  screen = 0
  sel = 1
  $enter_options.play()
