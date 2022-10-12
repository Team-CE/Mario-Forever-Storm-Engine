class_name LevelConstructor extends Node2D
tool

#export var LevelCamera: PackedScene = load('res://Objects/Core/Camera.tscn') # Camera For This Level
export var LevelHUD: PackedScene = load('res://Objects/Core/HUD.tscn') # HUD For This Level
export var PlayerScene: PackedScene = load('res://Objects/Core/Mario.tscn')
export var PrintMsg: bool = true

var WE: WorldEnvironment 
var BaseTileMap: TileMap

var Cam: Camera2D
var Player: Mario
var HUD: CanvasLayer


func _ready():
	
	pass

func _enter_tree():
	setup_editor()


func setup_editor() -> void:
	if !has('WorldEnvironment'):
		init_env()
	else:
		say('Env OK')
	
	if !has('TileMap'):
		init_tilemap()
	else:
		say('TileMap OK')
	
	add_HUD()
	add_player()
	add_cam()


func init_env() -> void:
	say('Env not found, making a new one...')
	WE = WorldEnvironment.new()
	WE.environment = load('res://Prefabs/world_env.tres')
	WE.set_name('Env')
	add_child(WE)
	WE.set_owner(self)

func init_tilemap() -> void:
	say('BaseTileMap not found, making a new one...')
	BaseTileMap = TileMap.new()
	BaseTileMap.tile_set = load('res://Prefabs/Tilesets/Generic.tres')
	
	BaseTileMap.set_name('TileMap')
	BaseTileMap.set_collision_layer_bit(1, true)
	BaseTileMap.set_collision_mask_bit(1, true)
	BaseTileMap.set_cell_size(Vector2(32, 32))
	BaseTileMap.add_to_group('Solid', true)
	BaseTileMap.set_cell(1, 13, 0)
	BaseTileMap.update_bitmask_area(Vector2(1, 13))
	
	add_child(BaseTileMap)
	BaseTileMap.set_owner(self)

func add_HUD() -> void:
	HUD = get_node_or_null('HUD')
	if !is_instance_valid(HUD):
		HUD = LevelHUD.instance()
	else:
		return
	
	say('HUD not found, adding a new one...')
	add_child(HUD)
	HUD.set_owner(self)

func add_player() -> void:
	Player = get_node_or_null('Mario')
	if !is_instance_valid(Player):
		Player = PlayerScene.instance()
	else:
		say('Player OK')
		return
	
	say('Player not found, adding a new one...')
	add_child(Player)
	Player.set_owner(self)

func add_cam() -> void:
	Cam = get_node_or_null('Mario/Camera')
	if !is_instance_valid(Cam):
		Cam = load('res://Objects/Core/Camera.tscn').instance()
	else:
		say('Camera OK')
		return
	
	# Mmmm... Camera... You actually won't see it
	say('Camera not found, adding a new one...')
	
	Player.add_child(Cam)
	Cam.set_owner(Player)

# Helps with determining which nodes are needed
func has(type: String) -> bool:
	var childs: Array
	
	if type == 'Camera2D': # Yes, Hardcoding...
		childs = Player.get_children()
	else:
		childs = get_children()
	
	for child in childs:
		#print(child.get_class(), ' ', type)
		if child.get_class() == type:
			return true
	return false

func say(mes: String) -> void:
	if PrintMsg:
		print('[%s]: ' % name, mes)
