extends Node
class_name Level
tool

export var time: int = 360
export var music: String = ''

onready var tileMap: TileMap
onready var BonusGroup: Node = Node.new()
onready var EnemyGroup: Node = Node.new()

func _ready():
  if !Engine.editor_hint:
    Global.time = time
    print('[Level]: Ready!')
    MusicEngine.play_music(music)
  elif not get_node('Mario'):
    tileMap = setup_tilemap()
    setup_groups()
    var mario: Node2D = load('res://Objects/Core/Mario.tscn').instance()
    mario.position = Vector2(48, 416)
    add_child(mario)
    mario.set_owner(self)
    var hud: CanvasLayer = load('res://Objects/Core/HUD.tscn').instance()
    add_child(hud)
    hud.set_owner(self)

func _enter_tree():
  pass

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

func setup_groups() -> void:
  add_child(BonusGroup)
  BonusGroup.name = 'BonusGroup'
  BonusGroup.set_owner(self)
  add_child(EnemyGroup)
  EnemyGroup.name = 'EnemyGroup'
  EnemyGroup.set_owner(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
  pass

