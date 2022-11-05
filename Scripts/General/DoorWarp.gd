tool
extends Area2D

enum TYPES {
	IN,
	OUT
}

export var id: int = 0
export(TYPES) var type: int = TYPES.IN
export var trigger_finish: bool = false
export var additional_options: Dictionary = {
	'set_scene_path': '',
	'add_scene': PackedScene
}

var counter: float = 0
var active: bool = false
var switch: bool = false

var door_warp: bool = true

var out_node
var disabled: bool = false
var finishline = null

func _ready() -> void:
	if !Engine.editor_hint:
		$Label.queue_free()
		
	var nodes = get_tree().get_nodes_in_group('DoorWarp')
		
	for node in nodes:
		if node.id == id and node.type == TYPES.OUT and 'door_warp' in node:
			out_node = node
			
	disabled = not out_node and (not 'set_scene_path' in additional_options or additional_options['set_scene_path'] == '') and (not 'add_scene' in additional_options or not additional_options['add_scene'].is_class('PackedScene')) and not trigger_finish
	
	if disabled:
		printerr('[CE ERROR] No out door-warp assigned for id ' + str(id) + ', it will not be functional. Create an out door-warp or set an additional option.')

	if not Engine.editor_hint:
		if trigger_finish:
			if !Global.current_scene.finish_node:
				printerr('[CE ERROR] No Finish Line found on level. Create one or untick the checkbox for warp ID ' + str(id))
				trigger_finish = false
				disabled = true
			else:
				finishline = Global.current_scene.finish_node

func _physics_process(delta: float) -> void:
	if Engine.editor_hint:
		$Label.text = str(id) + '\n' + ('IN' if type == TYPES.IN else 'OUT')
	else:
		# Door Warp Enter
		if Input.is_action_pressed('mario_up') and Global.is_mario_collide_area('InsideDetector', self) and type == TYPES.IN and not disabled and not active:
			active = true
			Global.Mario.position = position
			Global.Mario.controls_enabled = false
			Global.Mario.animation_enabled = false
			Global.Mario.velocity = Vector2.ZERO
			Global.Mario.get_node('Sprite').animation = 'Stopped'
			Global.Mario.invulnerable = true
		
		if !active: return
		
		if counter < 40:
			counter += 1 * Global.get_delta(delta)
			Global.Mario.get_node('Sprite').modulate.a -= 0.03 * Global.get_delta(delta)
			
		if counter >= 40:
			if 'add_scene' in additional_options and additional_options['add_scene'].is_class('PackedScene'):
				if !switch:
					var instanced_node = additional_options['add_scene'].instance()
					Global.current_scene.add_child(instanced_node)

			if out_node:
				if !switch:
					switch = true
					Global.Mario.get_node('Sprite').modulate.a = 0
					Global.Mario.position = out_node.position
				counter += 1 * Global.get_delta(delta)
				if Global.Mario.get_node('Sprite').modulate.a < 0.99:
					Global.Mario.get_node('Sprite').modulate.a += 0.03 * Global.get_delta(delta)

			elif 'set_scene_path' in additional_options and additional_options['set_scene_path'] != '':
				Global.goto_scene(additional_options['set_scene_path'])
				disabled = true
				active = false

			elif trigger_finish:
				finishline.act(true)
				Global.Mario.visible = false
				disabled = true
				active = false
			
		if counter >= 80:
			Global.Mario.get_node('Sprite').modulate.a = 1
			Global.Mario.controls_enabled = true
			Global.Mario.animation_enabled = true
			active = false
			Global.Mario.invulnerable = false
			if 'add_scene' in additional_options and additional_options['add_scene'].is_class('PackedScene'):
				switch = false
				counter = 0
			else:
				disabled = true
			

