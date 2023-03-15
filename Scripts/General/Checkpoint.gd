extends Area2D
signal checkpoint_activated

var active: bool = false
export var id: int = 0
export var custom_script: Script

var inited_script
var counter: float = 0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	var level = Global.current_scene
	if 'checkpoint_nodes' in level:
		level.checkpoint_nodes.append(self)
		
	if custom_script:
		inited_script = custom_script.new()
		if inited_script.has_method('_ready_mixin'):
			inited_script._ready_mixin(self)
		
	if Global.checkpoint_active == id:
		active = true
		$AnimatedSprite.animation = 'active'
		Global.Mario.position = position
		if Global.collectible_saved:
			get_tree().call_group('Collectible', 'queue_free')
		if (
			'time_after_checkpoint' in level
			and level.time_after_checkpoint.size() > 0
			and level.time_after_checkpoint[id] > 0
		):
			yield(get_tree(), 'idle_frame')
			Global.time = level.time_after_checkpoint[id]

func _physics_process(delta: float) -> void:
	rng.randi_range(0, 1)
	
	if is_instance_valid(self) and is_instance_valid(Global.Mario) and Global.is_mario_collide_area('InsideDetector', self) and !active:
		active = true
		emit_signal('checkpoint_activated', self)
		$AnimatedSprite.animation = 'active'
		$Sound.play()
		counter = 1
		Global.checkpoint_active = id
		Global.checkpoint_position = position
		$Sprite.visible = true
		if Global.collectible_obtained:
			Global.collectible_saved = true
		
	if counter > 0 and counter < 50:
		counter += 1 * Global.get_delta(delta)
	elif counter >= 50 and counter < 999:
		counter = 999
		var nodes = [get_node('MSound1'), get_node('MSound2'), get_node('MSound3')]
		var mnode = nodes[rng.randi_range(0, 2)] as AudioStreamPlayer
		mnode.stream.set_loop(false)
		mnode.play()
		
