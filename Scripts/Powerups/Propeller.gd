var isActivated: bool = false
var flyingDown: bool = false
var can_jump := false
var timer: float = 0

func _ready_mixin(_mario):
	flyingDown = false
	isActivated = false
	can_jump = false
	timer = 0
	Global.Mario.allow_custom_animation = false

func _process_mixin_physics(mario, delta):
	if Global.Mario.movement_type != Global.Mario.Movement.DEFAULT:
		flyingDown = false
		isActivated = false
		can_jump = false
		timer = 0
		Global.Mario.allow_custom_animation = false
		return

	if flyingDown:
		var collides = mario.get_node('BottomDetector').get_overlapping_bodies()
		for i in collides:
			if i.has_method('hit'):
				i.hit(true, false)
	
	if Input.is_action_just_released('mario_jump'):
		can_jump = true
	if mario.velocity.y > -500:
		can_jump = true
	
	if can_jump and Input.is_action_just_pressed('mario_jump') and not isActivated and not mario.is_on_floor() and Global.Mario.controls_enabled:
		isActivated = true
		timer = 0
		mario.velocity.y = -650
		mario.allow_custom_animation = true
		Global.play_base_sound('MISC_PropellerFly')
	
	mario.get_node('BottomDetector/CollisionBottom').scale.y = 0.5
	
	if isActivated:
		#mario.get_node('Sprite').animation = 'Launching'
		mario.animate_sprite('Launching')
		
		if not flyingDown:
			if Input.is_action_just_pressed('mario_crouch'):
				flyingDown = true
				Global.play_base_sound('MISC_PropellerDown')
				
				timer = 0
				
				var collides = mario.get_node('BottomDetector').get_overlapping_bodies()
				for i in collides:
					if i.has_method('hit'):
						i.hit(true, false)
			
			if mario.velocity.y > 250:
				mario.velocity.y = 250
			if mario.velocity.y < 0:
				mario.velocity.y -= 10 * Global.get_delta(delta)
# warning-ignore:incompatible_ternary
			mario.get_node('Sprite').speed_scale = 2.5 if mario.velocity.y < 0 else 1
		else:
			if Input.is_action_just_pressed('mario_up'):
				flyingDown = false
				timer = 0
				return
			timer += Global.get_delta(delta)
			if Input.is_action_pressed('mario_crouch'):
				timer = 0
			if timer > 20:
				flyingDown = false
			mario.velocity.y = 900
			mario.get_node('Sprite').speed_scale = 2.5
			mario.get_node('BottomDetector/CollisionBottom').position.y = mario.velocity.y / 32 * Global.get_delta(delta)
			mario.get_node('BottomDetector/CollisionBottom').scale.y = 2

	if mario.is_on_floor():
		if Input.is_action_pressed('mario_crouch'):
			mario.can_jump = false
		_ready_mixin(null)
