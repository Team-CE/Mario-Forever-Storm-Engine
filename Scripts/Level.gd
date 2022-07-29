extends Node2D
class_name Level
tool

export var time: int = 360
export var time_after_checkpoint: Array = []
export var music: Resource
export var death_height: float = 512
export var no_cliff: bool = false
export var sgr_scroll: bool = false
export var custom_scripts: Dictionary = {
  'on_enemy_death': null
}

onready var tileMap: TileMap
onready var worldEnv: WorldEnvironment

onready var mpMain = MusicPlayer.get_node('Main')
onready var mpStar = MusicPlayer.get_node('Star')

const popup_node = preload('res://Objects/Tools/PopupMenu.tscn')
const pause_node = preload('res://Objects/Tools/PopupMenu/Pause.tscn')
const options_node = preload('res://Objects/Tools/PopupMenu/Options.tscn')
var popup: CanvasLayer = null
var timer: Timer = null

func _ready():
  if !Engine.editor_hint:
    Global.currlevel = self
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    if not $Mario.custom_die_stream or Global.deaths == 0:
      Global.time = time
      MusicPlayer.get_node('TweenOut').remove_all()
      mpMain.stream = music
      mpMain.play()
      MusicPlayer.play_on_pause()
      mpMain.volume_db = 0
      mpStar.stop()
      mpStar.volume_db = 0
      AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
  
    var mario_cam = $Mario/Camera as Camera2D
    if Global.scroll > 0:
      mario_cam.smoothing_enabled = true
      mario_cam.smoothing_speed = 10
    if !Global.effects:
      $WorldEnvironment.environment.glow_enabled = false
    if Global.quality < 2:
      $WorldEnvironment.environment.glow_high_quality = false
      for node in get_children():
        if node.is_class('Light2D') and node.shadow_enabled:
          node.shadow_filter = 3
          node.shadow_buffer_size = 1024
    if Global.quality == 0:
      #$WorldEnvironment.environment.glow_bicubic_upscale = false
      for node in get_children():
        if node.is_class('Particles2D'):
          node.queue_free()
        if 'Particles' in node.name:
          for part in node.get_children():
            if part.is_class('Particles2D'):
              part.queue_free()
        if node.is_class('Light2D') and node.shadow_enabled:
          node.shadow_filter = 1
          node.shadow_buffer_size = 512
    $Mario.invulnerable = false
    
    get_parent().world.environment = null
    #get_parent().world.environment = $WorldEnvironment.environment.duplicate(true)
    #$WorldEnvironment.queue_free()
    
    if is_instance_valid(get_node_or_null('/root/fadeout')):
      get_node('/root/fadeout').call_deferred('queue_free')
    Global.reset_audio_effects()
    print('[Level]: Ready!')
  elif not get_node_or_null('Mario'):
    worldEnv = setup_worldenv()
    tileMap = setup_tilemap()
    var mario: Node2D = preload('res://Objects/Core/Mario.tscn').instance()
    mario.position = Vector2(48, 416)
    add_child(mario)
    mario.set_owner(self)
    var hud: CanvasLayer = preload('res://Objects/Core/HUD.tscn').instance()
    add_child(hud)
    hud.set_owner(self)

func setup_worldenv() -> WorldEnvironment:
  var newWE = WorldEnvironment.new()
  newWE.environment = load('res://Prefabs/world_env.tres')
  add_child(newWE)
  newWE.set_owner(self)
  newWE.set_name('WorldEnvironment')
  return newWE

func setup_tilemap() -> TileMap:
  var newTM = TileMap.new()
  newTM.tile_set = load('res://Prefabs/Tilesets/Generic.tres')
  add_child(newTM)
  newTM.set_owner(self)
  newTM.set_name('TileMap')
  newTM.set_collision_layer_bit(1, true)
  newTM.set_collision_mask_bit(1, true)
  newTM.set_cell_size(Vector2(32, 32))
  newTM.add_to_group('Solid', true)
  newTM.set_cell(1, 13, 0)
  newTM.update_bitmask_area(Vector2(1, 13))
  return newTM

# warning-ignore:unused_argument
#func _physics_process(delta):
#  pass

func _input(event):
  if Engine.editor_hint: return
  
  if !Input.is_action_pressed('debug_shift') and Global.debug:
    if event is InputEventKey and event.scancode >= 48 and event.scancode <= 57 and !event.echo and event.pressed:
      Global.play_base_sound('DEBUG_Toggle')
      Global.state = event.scancode - 49
      Global.Mario.appear_counter = 60
      
  if event.is_action_pressed('ui_pause'):
    if popup == null:
      popup = popup_node.instance()
      var pause = pause_node.instance()
      var options = options_node.instance()
      add_child(popup)
      popup.add_child(pause)
      popup.add_child(options)
      pause.get_node('pause').play()
      Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

      get_tree().paused = true

func _notification(what):
  if Engine.editor_hint: return
  if !Global.autopause: return
  if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
    if popup == null:
      timer = Timer.new()
      timer.wait_time = 0.2
      timer.one_shot = true
      timer.autostart = true
# warning-ignore:return_value_discarded
      timer.connect('timeout', self, '_on_timeout')
      call_deferred('add_child', timer)
  if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
    if popup == null and is_instance_valid(timer):
      timer.queue_free()

func _on_timeout():
  popup = popup_node.instance()
  var pause = pause_node.instance()
  var options = options_node.instance()
  call_deferred('add_child', popup)
  popup.call_deferred('add_child', pause)
  popup.call_deferred('add_child', options)
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  if is_instance_valid(timer):
    timer.call_deferred('queue_free')

  get_tree().paused = true

func activate_event(name: String, args: Array):
  if custom_scripts[name]:
    var inited_script = custom_scripts[name].new()
    if inited_script.has_method('_on_activation'):
      inited_script._on_activation(self, args)
      
