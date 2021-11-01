extends Node2D
class_name Level
tool

export var time: int = 360
export var music: Resource
export var death_height: float = 512
export var no_cliff: bool = false
export var sgr_scroll: bool = false

onready var tileMap: TileMap

func _ready():
  if !Engine.editor_hint:
    Global.time = time
    Global.currlevel = self
    #MusicEngine.play_music(music)
    MusicPlayer.stream = music
    MusicPlayer.play()
    print('[Level]: Ready!')
  elif not get_node('Mario'):
    tileMap = setup_tilemap()
    var mario: Node2D = load('res://Objects/Core/Mario.tscn').instance()
    mario.position = Vector2(48, 416)
    add_child(mario)
    mario.set_owner(self)
    var hud: CanvasLayer = load('res://Objects/Core/HUD.tscn').instance()
    add_child(hud)
    hud.set_owner(self)

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
func _physics_process(delta):
  pass

