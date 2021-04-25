extends Area2D

export var x_speed = 0
export var y_speed = 0
export var jump_counter = 0


func get_delta(delta):
	return 60 / (1 / (delta if not delta == 0 else 0.0001))


func _process(delta):
	if y_speed < 11:
		if Input.is_action_pressed('mario_jump') and y_speed < -1.5:
			y_speed += 0.3125 * get_delta(delta)
		else:
			y_speed += 0.8 * get_delta(delta)
	if y_speed > 10:
		y_speed = 10
		
	controls(delta)
	
	if x_speed > 0:
		x_speed -= 0.08 * get_delta(delta)
	if x_speed < 0:
		x_speed += 0.08 * get_delta(delta)
	
	if x_speed >= -0.08 and x_speed <= 0.08:
		x_speed = 0
	
	var bottom_overlaps = $BottomDetector.get_overlapping_bodies()
	if bottom_overlaps.size() > 0:
		for i in range(bottom_overlaps.size()):
			if bottom_overlaps[0] is TileMap and y_speed > 0:
				y_speed = 0
				jump_counter = 0
				
				# while get_overlapping_bodies().size() == 0:
				# 	position.y += 1
	
	position.y += y_speed * get_delta(delta)
	position.x += x_speed * get_delta(delta)
	
	animate()


func controls(delta):
	if Input.is_action_pressed('mario_jump') and jump_counter == 0:
		y_speed = -11
		jump_counter = 1
		$JumpSound.play()
	
	if Input.is_action_pressed('mario_right'):
		if x_speed > -0.4 and x_speed < 0.4:
			x_speed = 0.8
		elif x_speed < 3.5 and not Input.is_action_pressed('mario_fire'):
			x_speed += 0.18 * get_delta(delta)
		elif x_speed < 5 and Input.is_action_pressed('mario_fire'):
			x_speed += 0.18 * get_delta(delta)
	
	if Input.is_action_pressed('mario_left'):
		if x_speed > -0.4 and x_speed < 0.4:
			x_speed = -0.8
		elif x_speed > -3.5 and not Input.is_action_pressed('mario_fire'):
			x_speed -= 0.18 * get_delta(delta)
		elif x_speed > -5 and Input.is_action_pressed('mario_fire'):
			x_speed -= 0.18 * get_delta(delta)


func animate():
	if not (y_speed >= 0 and y_speed <= 0.1):
		$SmallMario.set_animation('Jumping')
	else:
		$SmallMario.set_animation('Stopped')
