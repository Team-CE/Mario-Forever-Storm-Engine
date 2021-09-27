extends AnimatedSprite

var CONTROLS_ASSIGN = [
  'mario_up',
  'mario_crouch',
  'mario_left',
  'mario_right',
  'mario_jump',
  'mario_fire'
]

var time
var sel = 0
var screen = 0
var selLimit

var fading_in = true
var fading_out = false
var circle_size = 0

var pos_y = 0

onready var controls_enabled: bool = false
onready var controls_changing: bool = false

func _ready() -> void:
#  var an : AnimationPlayer = get_parent().get_parent().get_node('AnimationPlayer')
#  an.connect('animation_finished',self,'animFinished')
  time = get_tree().create_timer(0)
  connect('animation_finished', self, 'animends')
  $fadeout.play()
  MusicEngine.set_volume(Global.musicBar / 12)
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), Global.soundBar / 12)

func _process(delta):
  # Random Blinking
  if !playing && time.time_left <= 0.0:
    randomize()                          # For full random
    var rand = randi() % 5 + 2           # Get a Random number
    time = get_tree().create_timer(rand) # Create a new SceneTimer
    yield(time, 'timeout')               # Delay
    playing = true                       # Set anim play
    
  if controls_enabled:
    controls()

  if fading_out:
    circle_size -= 0.01 * Global.get_delta(delta)
    get_parent().get_node('Transition').visible = true
    get_parent().get_node('Transition').material.set_shader_param('circle_size', circle_size)
  else:
    get_parent().get_node('Transition').visible = false

  if fading_in:
    circle_size += 0.01 * Global.get_delta(delta)
    get_parent().get_node('Transition').visible = true
    get_parent().get_node('Transition').material.set_shader_param('circle_size', circle_size)
    if circle_size > 0.623:
      get_parent().get_node('Transition').visible = false
      circle_size = 0.623
      fading_in = false
      controls_enabled = true

  position.y += (pos_y - position.y) * 0.2
    
  var base_y = screen * 480
  $Camera2D.limit_top = base_y
  $Camera2D.limit_bottom = base_y + 480
    
  match screen:
    0:
      pos_y = 359 + (29 * sel)
      position.x = 248
      selLimit = 2
      
    1:
      pos_y = 550 + (37.5 * sel)
      position.x = 224
      selLimit = 9
      updateOptions()
      $Credits.hide()
    2:
      pos_y = 1018 + (64 * sel)
      position.x = 172
      selLimit = 6
    3:
      pos_y = 1920 + 216
      position.x = 240
      selLimit = 0
      $Credits.position.y -= 1 * Global.get_delta(delta)
      $Credits.show()
    
func controls():
  if Input.is_action_just_pressed('ui_down') and sel < selLimit:
    sel += 1
    if Global.effects:
      var effect = MarioHeadEffect.new(position)
      get_parent().add_child(effect)
    $select_main.play()
  elif Input.is_action_just_pressed('ui_up') and sel > 0:
    sel -= 1
    if Global.effects:
      var effect = MarioHeadEffect.new(position)
      get_parent().add_child(effect)
    $select_main.play()
  
  match screen:
    0:    # _____ MAIN _____
      if Input.is_action_just_pressed('ui_accept'):
        match sel:
          0:
            controls_enabled = false
            $letsgo.play()
            MusicEngine.fade_out(0.3)
            yield(get_tree().create_timer( 2.5 ), 'timeout')
            $fadeout.play()
            fading_out = true
            MusicEngine.islooping = false
            MusicEngine.track_ended('')
            yield(get_tree().create_timer( 1.4 ), 'timeout')
            fading_out = false
            MusicEngine.islooping = true
            if Global.musicBar > -100:
              MusicEngine.set_volume(Global.musicBar / 12)
            if Global.musicBar == -100:
              MusicEngine.set_volume(-1000)
            get_tree().change_scene('res://Stages/SaveGameRoom.tscn')
          1:
            screen += 1
            sel = 0
            $enter_options.play()
          2:
            controls_enabled = false
            $enter_options.play()
            MusicEngine.fade_out(0.2)
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
            $Credits.pos_y = 0
            MusicEngine.track_ended('credits.mod')
            #MusicEngine.play_music('credits.mod')
            #MusicEngine.islooping = true
          9:
            screen = 0
            sel = 1
            $enter_options.play()
            saveOptions()
      if Input.is_action_just_pressed('ui_right'):
        match sel:
          0:
            if Global.soundBar < 0:
              Global.soundBar += 10
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), Global.soundBar / 12)
              $tick.play()
          1:
            if Global.musicBar < 0:
              Global.musicBar += 10
              MusicEngine.set_volume(Global.musicBar / 12)
              $tick.play()
          2:
            if !Global.effects:
              Global.effects = true
              $change.play()
          3:
            if Global.scroll < 2:
              Global.scroll += 1
              $change.play()
          5:
            if !Global.vsync:
              Global.vsync = true
              $change.play()
          6:
            if !Global.rpc:
              Global.rpc = true
              $change.play()
              
      elif Input.is_action_just_pressed('ui_left'):
        match sel:
          0:
            if Global.soundBar > -100:
              Global.soundBar -= 10
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), Global.soundBar / 12)
              $tick.play()
            if Global.soundBar == -100:
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), -1000)
          1:
            if Global.musicBar > -100:
              Global.musicBar -= 10
              MusicEngine.set_volume(Global.musicBar / 12)
              $tick.play()
            if Global.musicBar == -100:
              MusicEngine.set_volume(-1000)
          2:
            if Global.effects:
              Global.effects = false
              $change.play()
          3:
            if Global.scroll > 0:
              Global.scroll -= 1
              $change.play()
          5:
            if Global.vsync:
              Global.vsync = false
              $change.play()
          6:
            if Global.rpc:
              Global.rpc = false
              $change.play()
      elif Input.is_action_just_pressed('ui_cancel'):
        screen = 0
        sel = 1
        saveOptions()
    2:    # _____ CONTROLS _____
      if Input.is_action_just_pressed('ui_accept') and sel < 6:
        get_parent().get_node('Label' + str(sel)).text = 'PRESS A KEY TO ASSIGN'
        controls_changing = true
        controls_enabled = false
        get_tree().set_input_as_handled()

      if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept') and sel == 6:
        screen = 1
        sel = 4
        controls_changing = false
        controls_enabled = true
    3:    # _____ CREDITS _____
      if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept'):
        screen = 1
        sel = 8
        MusicEngine.track_ended('start.xm')
        #MusicEngine.play_music('start.xm')
         
func animends():
  playing = false

func _input(event):
  if event is InputEventKey and event.pressed and controls_changing:
    if not event.is_action("ui_cancel"):
      var scancode = OS.get_scancode_string(event.scancode)
      get_parent().get_node('Label' + str(sel)).text = scancode
      for old_event in InputMap.get_action_list(CONTROLS_ASSIGN[sel]):
        InputMap.action_erase_event(CONTROLS_ASSIGN[sel], old_event)
      InputMap.action_add_event(CONTROLS_ASSIGN[sel], event)
    else:
      pass
    controls_changing = false
    controls_enabled = true
  
func updateOptions():
  get_parent().get_node('Buttons/SoundBar').frame = 10 + (Global.soundBar / 10)
  get_parent().get_node('Buttons/MusicBar').frame = 10 + (Global.musicBar / 10)
  get_parent().get_node('Buttons/Effects').frame = Global.effects
  get_parent().get_node('Buttons/Scroll').frame = Global.scroll
  get_parent().get_node('Buttons/VSync').frame = Global.vsync
  get_parent().get_node('Buttons/RPC').frame = Global.rpc

func saveOptions():
  Global.toSaveInfo = {
    'SoundVol': Global.soundBar,
    'MusicVol': Global.musicBar,
    'Efekty': Global.effects,
    'Scroll': Global.scroll,
    'VSync': Global.vsync,
    'RPC': Global.rpc,
    'Controls': CONTROLS_ASSIGN
  }
  Global.saveInfo(JSON.print(Global.toSaveInfo))
