extends AnimatedSprite

var time
var sel = 0
var screen = 0
var selLimit

onready var controls_enabled: bool = true

func _ready() -> void:
#  var an : AnimationPlayer = get_parent().get_parent().get_node("AnimationPlayer")
#  an.connect("animation_finished",self,"animFinished")
  time = get_tree().create_timer(0)
  connect("animation_finished",self,'animends')
  MusicEngine.set_volume(Global.musicBar / 12)
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), Global.soundBar / 12)

func _process(delta):
  # Random Blinking
  if !playing && time.time_left <= 0.0:
    randomize()                          #For full random
    var rand = randi()%5+2               #Get a Random number
    time = get_tree().create_timer(rand) #Create a new SceneTimer
    yield(time, "timeout")               #Delay
    playing = true                       #Set anim play
    
  if controls_enabled:
    controls(delta)
    
  var base_y = screen * 480
  $Camera2D.limit_top = base_y
  $Camera2D.limit_bottom = base_y + 480
    
  match screen:
    0:
      position.y = 359 + (29 * sel)
      position.x = 248
      selLimit = 2
      
    1:
      position.y = 550 + (37.5 * sel)
      position.x = 224
      selLimit = 9
      updateOptions()
      $Credits.hide()
    2:
      position.y = 960 + (37.5 * sel)
      position.x = 224
      selLimit = 5
    3:
      position.y = 1920 + 216
      position.x = 240
      selLimit = 0
      $Credits.position.y -= 1 * Global.get_delta(delta)
      $Credits.show()
    
func controls(delta):
  if Input.is_action_just_pressed("ui_down") and sel < selLimit:
    sel += 1
    var effect = MarioHeadEffect.new(position)
    get_parent().add_child(effect)
    $select_main.play()
  elif Input.is_action_just_pressed("ui_up") and sel > 0:
    sel -= 1
    var effect = MarioHeadEffect.new(position)
    get_parent().add_child(effect)
    $select_main.play()
  
  match screen:
    0: 
      if Input.is_action_just_pressed("ui_accept"):
        match sel:
          0:
            controls_enabled = false
            $letsgo.play()
            MusicEngine.fade_out(0.3)
            yield(get_tree().create_timer( 3 ), "timeout")
            $fadeout.play()
          1:
            screen += 1
            sel = 0
            $enter_options.play()
          2:
            controls_enabled = false
            $enter_options.play()
    1:
      if Input.is_action_just_pressed("ui_accept"):
        match sel:
          4:
            screen = 2
            sel = 0
            $enter_options.play()
          8:
            screen = 3
            sel = 0
            $enter_options.play()
            $Credits.position.y = 0
            MusicEngine.track_ended()
            MusicEngine.play_music("credits.mod")
          9:
            screen = 0
            sel = 1
            $enter_options.play()
            Global.toSaveInfo = {
              "SoundVol": Global.soundBar,
              "MusicVol": Global.musicBar,
              "Efekty": Global.effects,
              "Scroll": Global.scroll,
              "VSync": Global.vsync,
              "RPC": Global.rpc
            }
            Global.saveInfo(JSON.print(Global.toSaveInfo))
      if Input.is_action_just_pressed("ui_right"):
        match sel:
          0:
            if Global.soundBar < 0:
              Global.soundBar += 10
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), Global.soundBar / 12)
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
              
      elif Input.is_action_just_pressed("ui_left"):
        match sel:
          0:
            if Global.soundBar > -100:
              Global.soundBar -= 10
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), Global.soundBar / 12)
              $tick.play()
            if Global.soundBar == -100:
              AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -1000)
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
      elif Input.is_action_just_pressed("ui_cancel"):
        screen = 0
        sel = 1
        Global.toSaveInfo = {
          "SoundVol": Global.soundBar,
          "MusicVol": Global.musicBar,
          "Efekty": Global.effects,
          "Scroll": Global.scroll,
          "VSync": Global.vsync,
          "RPC": Global.rpc
        }
        Global.saveInfo(JSON.print(Global.toSaveInfo))
    2:
      if Input.is_action_just_pressed("ui_cancel"):
        screen = 1
        sel = 4
    3:
      if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
        screen = 1
        sel = 8
        MusicEngine.track_ended()
        MusicEngine.play_music("start.xm")
         
func animends():
  playing = false

func updateOptions():
  get_parent().get_node("Buttons/SoundBar").frame = 10 + (Global.soundBar / 10)
  get_parent().get_node("Buttons/MusicBar").frame = 10 + (Global.musicBar / 10)
  get_parent().get_node("Buttons/Effects").frame = Global.effects
  get_parent().get_node("Buttons/VSync").frame = Global.vsync
  get_parent().get_node("Buttons/RPC").frame = Global.rpc
