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

func get_class(): return 'Level'
func is_class(name) -> bool: return name == 'Level' or .is_class(name) 

func _ready():
	if !Engine.editor_hint:
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
		
		if !Global.effects:
			$WorldEnvironment.environment.glow_enabled = false
		if Global.quality < 2:
			$WorldEnvironment.environment.glow_high_quality = false
			for node in get_children():
				if node.is_class('Light2D') and node.shadow_enabled:
					node.shadow_filter = 0
					node.shadow_buffer_size = 512
					print(node)
		if Global.quality == 0:
			#$WorldEnvironment.environment.glow_bicubic_upscale = false
			for node in get_children():
				if node.is_class('Particles2D'):
					node.emitting = false
					node.visible = false
				if 'Particles' in node.name:
					for part in node.get_children():
						if part.is_class('Particles2D'):
							part.emitting = false
							part.visible = false
				if node.is_class('Light2D') and node.shadow_enabled:
					node.shadow_filter = 0
					node.shadow_buffer_size = 512
					node.shadow_enabled = false
		$Mario.invulnerable = false
		
		get_parent().world.environment = null
		#get_parent().world.environment = $WorldEnvironment.environment.duplicate(true)
		#$WorldEnvironment.queue_free()
		
		if has_node('/root/fadeout'):
			get_node('/root/fadeout').call_deferred('queue_free')
		Global.reset_audio_effects()

		if Global.scroll > 0:
			yield(get_tree(), 'idle_frame')
			var cam = Global.current_camera as Camera2D
			if !cam: return
			cam.smoothing_enabled = true
			cam.smoothing_speed = 10
		
		print('[Level]: Ready!')
	elif not has_node('Mario'):
		worldEnv = setup_worldenv()
		tileMap = setup_tilemap()
		var mario: Node2D = load('res://Objects/Core/Mario.tscn').instance()
		mario.position = Vector2(48, 416)
		add_child(mario)
		mario.set_owner(self)
		var camera: Camera2D = load('res://Objects/Core/Camera.tscn').instance()
		mario.add_child(camera)
		camera.set_owner(self)
		var hud: CanvasLayer = load('res://Objects/Core/HUD.tscn').instance()
		add_child(hud)
		hud.set_owner(self)
		var brush = Brush2D.new()
		add_child(brush)
		brush.set_owner(self)
		brush.set_name('Brush2D')

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
#	pass

func _input(event):
	if Engine.editor_hint: return
	
	if !Input.is_action_pressed('debug_shift') and Global.debug:
		if event is InputEventKey and event.scancode >= 48 and event.scancode <= 57 and !event.echo and event.pressed:
			Global.play_base_sound('DEBUG_Toggle')
			Global.state = event.scancode - 49
			Global.Mario.appear_counter = 60
			


func activate_event(name: String, args: Array):
	if custom_scripts[name]:
		var inited_script = custom_scripts[name].new()
		if inited_script.has_method('_on_activation'):
			inited_script._on_activation(self, args)
			
