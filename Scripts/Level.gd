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

const pause_menu = preload('res://Objects/Tools/PopupMenu.tscn')
var popup: CanvasLayer = null
var popa: CanvasLayer = null

func _ready():
  if !Engine.editor_hint:
    Global.currlevel = self
    $WorldEnvironment.environment.dof_blur_near_enabled = false
    if not $Mario.custom_die_stream or Global.deaths == 0:
      Global.time = time
      MusicPlayer.get_node('TweenOut').remove_all()
      mpMain.stream = music
      mpMain.play()
      mpMain.volume_db = 0
      mpStar.stop()
      mpStar.volume_db = 0
      if Global.musicBar > -100:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), Global.musicBar / 5)
      if Global.musicBar == -100:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
  
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
  if event.is_action_pressed('ui_pause'):
    if popup == null:
      popup = pause_menu.instance()
      for node in popup.get_children():
        if node.get_class() == 'Node' and not node.get_name() == 'Pause':
          node.queue_free()
      popup.get_node('pause').play()
      add_child(popup)

      get_tree().paused = true

func _notification(what):
  if Engine.editor_hint: return
  if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
    if popup == null and not get_tree().paused:
      popup = pause_menu.instance()
      print('creating pause')
      for node in popup.get_children():
        if node.get_class() == 'Node' and not node.get_name() == 'Pause':
          node.queue_free()
      call_deferred('add_child', popup)

      get_tree().paused = true

func activate_event(name: String, args: Array):
  if custom_scripts[name]:
    var inited_script = custom_scripts[name].new()
    if inited_script.has_method('_on_activation'):
      inited_script._on_activation(self, args)
      
