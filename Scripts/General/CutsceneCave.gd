extends Node2D


func get_class(): return 'Cutscene'
func is_class(name) -> bool: return name == 'Cutscene' or .is_class(name) 

func _ready():
	$Mario.controls_enabled = false
	yield(get_tree(), 'idle_frame')
	$Mario.velocity.x = 440
	if Global.starman_saved:
		Global.Mario.get_node('Sprite').material.set_shader_param('mixing', true)
	
func _physics_process(_delta):
	if $Mario.velocity.x < 75:
		$Mario.velocity.x = 75
	if $Mario.get_node('InsideDetector').get_overlapping_areas().has($Warp) and not $Warp.active:
		$letspipe.play()
		$Warp.calc_pos = Vector2($Warp.position.x - 16, $Warp.position.y + 16)
		$Warp.active = true
		$Mario.animate_sprite('Walking')
		$Mario/Sprite.speed_scale = 5
		$Mario/Sprite.flip_h = false
		$Warp.warp_dir = Vector2(1, 0)
	if $Warp.counter > 36:
		$Mario/Sprite.visible = false
		if is_instance_valid($Mario.shoe_node):
			$Mario.shoe_node.get_node('AnimatedSprite').visible = false

func _input(event):
	if 'echo' in event and event.echo: return
	if !Input.is_action_just_pressed('mario_jump'): return
	
	var to_jump
	for i in Global.current_scene.get_tree().get_nodes_in_group('Warp'):
		if 'set_scene_path' in i.additional_options and i.additional_options['set_scene_path'] != '':
			to_jump = i.additional_options['set_scene_path']
			break
	if !to_jump:
		return
	$letsgo.pause_mode = PAUSE_MODE_PROCESS
	MusicPlayer.pause_mode = PAUSE_MODE_PROCESS
	MusicPlayer.fade_out($letsgo, 0.5)
	Global.goto_scene_with_transition(to_jump)
