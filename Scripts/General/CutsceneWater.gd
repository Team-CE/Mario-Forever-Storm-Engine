extends Node2D

export var change_to_scene: String
var camera
var touched_water: bool

func _ready():
	$Mario.controls_enabled = false
	yield(get_tree(), 'idle_frame')
	$Mario.velocity.x = 125
	camera = Global.current_camera

func _process(delta):
	# Constant speed
	if $Mario.velocity.x < 125 && $Mario.velocity.x > 1:
		$Mario.velocity.x = 125
	# Jump
	if get_node_or_null('JumpPos') and $Mario.position.x > $JumpPos.position.x:
		$JumpPos.queue_free()
		$Mario.jump()
		yield(get_tree(), 'idle_frame')
		$Mario.velocity.y = -400
	# Lowering jump gravity for epicness(tm)
	if $Mario.position.x > 10 and $Mario.jump_counter > 0 and $Mario.movement_type != $Mario.Movement.SWIMMING:
		$Mario.velocity.y -= 40 * Global.get_delta(delta)
	# Le touch of a bird
	if $Mario.movement_type == $Mario.Movement.SWIMMING:
		if !touched_water:
			touched_water = true
			$Mario.velocity.y = 50
	
	# Jump to next scene
	if $Mario.position.y > 720:
		Global.goto_scene(change_to_scene)
