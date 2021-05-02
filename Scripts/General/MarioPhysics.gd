extends Node2D

export var x_speed = 0
export var y_speed = 0
export var jump_counter = 0
export var can_jump = true

func is_over_backdrop(obj):
	var overlaps = obj.get_overlapping_bodies()
	if overlaps.size() > 0:
		for i in range(overlaps.size()):
			if overlaps[0] is TileMap:
				return true
	return false

func _process(delta):
	if y_speed < 11:
		if Input.is_action_pressed('mario_jump') and y_speed < -1.5:
			y_speed += 0.3125 * Global.get_delta(delta)
		else:
			y_speed += 1 * Global.get_delta(delta)
	if y_speed > 10:
		y_speed = 10
		
	controls(delta)
	
	if x_speed > 0:
		x_speed -= 0.1 * Global.get_delta(delta)
	if x_speed < 0:
		x_speed += 0.1 * Global.get_delta(delta)
	
	if x_speed >= -0.08 and x_speed <= 0.08:
		x_speed = 0
	
	if is_over_backdrop($BottomDetector) and y_speed > 0:
		if is_over_backdrop($InsideDetector):
			position.y -= 16
		y_speed = 0
		jump_counter = 0
		position.y = round(position.y / 32) * 32
	
	if is_over_backdrop($TopDetector) and y_speed < 0:
		y_speed = 0
	
	if not (is_over_backdrop($TopDetector) and not is_over_backdrop($BottomDetector)) and ((is_over_backdrop($RightDetector) and x_speed >= 0.08) or (is_over_backdrop($LeftDetector) and x_speed <= -0.08)):
		x_speed = 0
	
	if is_over_backdrop($SmallRightDetector):
		position.x -= 1 * Global.get_delta(delta)
	
	if is_over_backdrop($SmallLeftDetector):
		position.x += 1 * Global.get_delta(delta)
	
	if is_over_backdrop($SmallRightDetector) and is_over_backdrop($SmallLeftDetector):
		position.x += (1 if $SmallMario.flip_h else -1) * Global.get_delta(delta)
	
	position.y += y_speed * Global.get_delta(delta)
	position.x += x_speed * Global.get_delta(delta)
	
	animate()
	debug()

func controls(delta):
	if Input.is_action_pressed('mario_jump') and jump_counter == 0:
		y_speed = -11
		jump_counter = 1
		$JumpSound.play()
	
	if Input.is_action_pressed('mario_right'):
		if x_speed > -0.4 and x_speed < 0.4:
			x_speed = 0.8
		elif x_speed < 3.5 and not Input.is_action_pressed('mario_fire'):
			x_speed += 0.23 * Global.get_delta(delta)
		elif x_speed < 7 and Input.is_action_pressed('mario_fire'):
			x_speed += 0.23 * Global.get_delta(delta)
	
	if Input.is_action_pressed('mario_left'):
		if x_speed > -0.4 and x_speed < 0.4:
			x_speed = -0.8
		elif x_speed > -3.5 and not Input.is_action_pressed('mario_fire'):
			x_speed -= 0.23 * Global.get_delta(delta)
		elif x_speed > -7 and Input.is_action_pressed('mario_fire'):
			x_speed -= 0.23 * Global.get_delta(delta)

func animate():
	if not y_speed == 0:
		$SmallMario.set_animation('Jumping')
	elif abs(x_speed) < 0.8:
		$SmallMario.set_animation('Stopped')
	
	if x_speed <= -0.8:
		$SmallMario.flip_h = true
		if not $SmallMario.animation == 'Walking' and y_speed == 0:
			$SmallMario.set_animation('Walking')
	if x_speed >= 0.8:
		$SmallMario.flip_h = false
		if not $SmallMario.animation == 'Walking' and y_speed == 0:
			$SmallMario.set_animation('Walking')
	
	if $SmallMario.animation == 'Walking':
		$SmallMario.speed_scale = abs(x_speed) * 2.5 + 4

func debug():
	$DebugLayer/DebugText.text = 'x speed = ' + str(x_speed) + '\ny speed = ' + str(y_speed) + '\nanimation: ' + str($SmallMario.animation).to_lower()
