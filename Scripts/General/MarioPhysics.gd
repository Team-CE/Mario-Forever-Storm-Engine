extends KinematicBody2D

signal bottom_collider
signal jumped

export var powerup_animations: Dictionary = {}
export var powerup_scripts: Dictionary = {}
export var target_gravity_angle: float = 0
export var sections_scroll: bool = true
export var camera_addon: Script
export var custom_die_stream: Resource

var inited_camera_addon

var ready_powerup_scripts: Dictionary = {}

export var velocity: Vector2
var jump_counter: int = 0
var jump_internal_counter: float = 100
var can_jump: bool = false
var crouch: bool = false
var is_stuck: bool = false
var prelanding: bool = false
var motion_disabled: bool = false

var ignore_stuck: bool = false # Set to true if there are issues with mario getting stuck

enum Movement {
	DEFAULT,
	SWIMMING,
	CLIMBING,
	NONE
 }

var top_collider_counter: float = 0

var is_big_collision: bool = false
var selected_state: int = -1

onready var movement_type: int = Movement.DEFAULT
onready var dead: bool = false
onready var dead_hasJumped: bool = false
onready var dead_gameover: bool = false
onready var dead_counter: float = 0

onready var appear_counter: float = 0
onready var shield_star: bool = false
onready var shield_counter: float = 0
onready var star_kill_count: int = 0
onready var exceptions_added = false

onready var launch_counter: float = 0
onready var controls_enabled: bool = true
onready var animation_enabled: bool = true
onready var allow_custom_animation: bool = false
onready var physics_enabled: bool = true
onready var invulnerable: bool = false							 # True while warping or finishing the level

var shoe_node: Object
var shoe_type: int
var is_in_shoe: bool

var faded: bool = false

var gameovercont_node = load('res://Objects/Tools/PopupMenu/GameOver.tscn')

func _ready() -> void:
	Global.Mario = self
# warning-ignore:return_value_discarded
	Global.connect('OnPlayerLoseLife', self, 'kill')
	$DebugText.visible = false
	$Sprite.material.set_shader_param('mixing', false)
	
	if camera_addon:
		inited_camera_addon = camera_addon.new()
		if inited_camera_addon.has_method('_ready_camera'):
			inited_camera_addon._ready_camera(self)
	
	# Creating working instances of provided scripts
	var p_keys = powerup_scripts.keys()
	for i in range(len(p_keys)):
		ready_powerup_scripts[p_keys[i]] = powerup_scripts[p_keys[i]].new()

func is_over_backdrop(obj, ignore_hidden) -> bool:
	var overlaps = obj.get_overlapping_bodies()

	if overlaps.size() > 0 && (overlaps[0] is TileMap or overlaps[0].is_in_group('Solid')) and (overlaps[0].visible or ignore_hidden):
		return true

	return false

func is_over_platform() -> bool:
	if get_slide_count() > 0:
		var collider = get_slide_collision(0).collider
		return collider.is_in_group('Platform')
	else:
		return false

func _physics_process(delta) -> void:
	if has_node('Camera'):
		_process_camera(delta)
	
	if !physics_enabled:
		return
	
	var target_gravity_enabled: bool = true
	var overlaps = $InsideDetector.get_overlapping_areas()
	for i in overlaps:
		if 'gravity_point' in i and i.gravity_point:
			target_gravity_enabled = false
			
	if target_gravity_enabled:
		$Sprite.rotation = lerp_angle($Sprite.rotation, deg2rad(0.0), 0.35 * Global.get_delta(delta))
		if is_instance_valid(Global.current_camera):
			Global.current_camera.rotation = lerp_angle(Global.current_camera.rotation, deg2rad(0.0), 0.35 * Global.get_delta(delta))
		if round(rotation_degrees * 10) != round(target_gravity_angle * 10):
			#print('rotate', rotation_degrees, target_gravity_angle)
			if abs(round(rotation_degrees - target_gravity_angle)) > 10:
				$Sprite.rotation_degrees = rotation_degrees - target_gravity_angle
				if is_instance_valid(Global.current_camera):
					Global.current_camera.rotation_degrees = rotation_degrees - target_gravity_angle
			rotation_degrees = target_gravity_angle
		#rotation = lerp_angle(rotation, deg2rad(target_gravity_angle), 0.35 * Global.get_delta(delta))
	else:
		target_gravity_angle = rotation_degrees
		
	#$Sprite.modulate.a = 0.5 if Global.debug_fly else 1
	
	$BottomDetector/CollisionBottom.position.y = 5 + velocity.y / 100 * Global.get_delta(delta)

	if not dead:
		if not Global.debug_fly:
			_process_alive(delta)
		else:
			_process_debug_fly(delta)
	else:
		_process_dead(delta)

	if velocity.y > 500:
		velocity.y = 500

	if jump_internal_counter < 100:
		jump_internal_counter += 1 * Global.get_delta(delta)
	
	if inited_camera_addon and inited_camera_addon.has_method('_process_physics_camera'):
		inited_camera_addon._process_physics_camera(self, delta)
	if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_process_mixin_physics') and not dead:
		ready_powerup_scripts[Global.state]._process_mixin_physics(self, delta)


func _process_alive(delta) -> void:
	if selected_state != Global.state:
		selected_state = Global.state
		if selected_state > 0 and test_move(global_transform, Vector2(0, -6).rotated(rotation)):
			velocity.y = 0
			crouch = true
			is_stuck = true
		if not Global.state in powerup_animations:
			printerr('[CE ERROR] Mario: Animations for state ' + str(Global.state) + ' don\'t exist!')
			return
		if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_ready_mixin'):
			ready_powerup_scripts[Global.state]._ready_mixin(self)
		$Sprite.frames = powerup_animations[Global.state]
		if is_in_shoe:
			$AnimationPlayer.play('Small' if Global.state == 0 else 'Big')
		if shield_counter > 0:
			$Sprite.visible = true
	
	if Global.shoe_type != 0 and !is_instance_valid(shoe_node):
		var shoe
		if Global.shoe_type == 1:
			shoe = load('res://Objects/Bonuses/ShoeRed.tscn').instance()
		#elif Global.shoe_type == 2:
		#	shoe = load('res://Objects/Bonuses/ShoeGreen.tscn').instance()
		Global.current_scene.add_child(shoe)
		shoe.global_position = global_position
		bind_shoe(shoe.get_instance_id())

	var danimate: bool = false
	if movement_type == Movement.SWIMMING:	# Faster than match
		movement_swimming(delta)
	elif movement_type == Movement.CLIMBING:
		movement_climbing(delta)
	elif !is_in_shoe:
		danimate = true
		movement_default(delta)
		if $AnimationPlayer.current_animation != 'RESET':
			$AnimationPlayer.play('RESET')
			$AnimationPlayer.stop(true)
	elif movement_type == Movement.DEFAULT:
		movement_default(delta)
		animate_shoe(delta)
	
	if movement_type == Movement.NONE: return
		
	if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('_process_mixin'):
		ready_powerup_scripts[Global.state]._process_mixin(self, delta)
		
	if not Global.state == 6: # Fix for propeller powerup animation
		allow_custom_animation = false
		$BottomDetector/CollisionBottom.scale.y = 0.5
	
	
	var bottom_collisions = $BottomDetector.get_overlapping_bodies()
	if is_on_floor():
		for collider in bottom_collisions:
			emit_signal('bottom_collider', collider)
			if collider.has_method('_standing_on'):
				collider._standing_on()
	
	if shield_star:
		star_logic()
		if !exceptions_added:
			$BottomDetector.collision_layer = 0b100 # Only layer 3, which are springs
			$BottomDetector.collision_mask = 0b100
			exceptions_added = true
		$Sprite.material.set_shader_param('mixing', true)
		# Starman music Fade out
		
		if shield_counter <= 125 and Global.musicBar > 0 and !faded:
			MusicPlayer.fade_out(MusicPlayer.star, 3.0)
			faded = true
		if shield_counter <= 0:
			MusicPlayer.star.stop()
			MusicPlayer.starmpt.stop()
			MusicPlayer.star.pause_mode = PAUSE_MODE_STOP
# warning-ignore:return_value_discarded
			MusicPlayer.tween_out.stop_all()
			if Global.music_loader and Global.music_loader.playing and not Global.level_ended:
				Global.music_loader.call_deferred('play')
			$BottomDetector.collision_layer = 0b111 # All 3 layers
			$BottomDetector.collision_mask = 0b111
			$Sprite.material.set_shader_param('mixing', false)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
			shield_star = false
			exceptions_added = false
			star_kill_count = 0
	
	if controls_enabled:
		controls(delta)
	
	var camera = Global.current_camera
	
	if camera and position.y > camera.limit_bottom + 64 and controls_enabled:
		if 'no_cliff' in Global.current_scene and Global.current_scene.no_cliff:
			position.y -= 550
		else:
			if 'sgr_scroll' in Global.current_scene and !Global.current_scene.sgr_scroll:
				Global._pll()
			elif has_node('../StartWarp'):
				get_node('../StartWarp').active = true
				get_node('../StartWarp').counter = 61
			
	if camera and position.y < camera.limit_top - 64 and controls_enabled and 'no_cliff' in Global.current_scene and Global.current_scene.no_cliff:
		position.y += 570

	if top_collider_counter > 0:
		top_collider_counter -= 1 * Global.get_delta(delta)

	if is_on_ceiling():
		top_collider_counter = 3

	if top_collider_counter > 0:
		var collisions = $TopDetector.get_overlapping_bodies()
		for collider in collisions:
			if collider.has_method('hit'):
				collider.hit()

	vertical_correction(5) # Corner correction like in original Mario games
	horizontal_correction(10) # One tile gap runover ability
	var old_velocity = Vector2.ZERO + velocity # Fix for slopes
	if !motion_disabled:
		velocity = move_and_slide_with_snap(velocity.rotated(rotation), Vector2(0, 1).rotated(rotation) * (8 if !(jump_counter or movement_type == Movement.CLIMBING) else 1), Vector2(0, -1).rotated(rotation), true, 4, 0.96, false).rotated(-rotation)
	if !is_on_wall():
		velocity.x = old_velocity.x
	
	fix_velocity_y(delta)

	update_collisions()
		
	if animation_enabled and danimate: animate_default(delta)
	if Global.debug:
		debug()
	
	$Sprite.offset.y = 0 - $Sprite.frames.get_frame($Sprite.animation, $Sprite.frame).get_size().y
	$Sprite.offset.x = 0 - $Sprite.frames.get_frame($Sprite.animation, $Sprite.frame).get_size().x / 2

func _process_dead(delta) -> void:
	if dead_counter == 0:
		Global.state = 0
		$Sprite.frames = powerup_animations[0]
		animate_default(delta)
	
	var colDisabled
	if not colDisabled:
		$TopDetector/CollisionTop.disabled = true
		$BottomDetector/CollisionBottom.disabled = true
		$TopWaterDetector/Collision.disabled = true
		$Collision.disabled = true
		$CollisionBig.disabled = true
		$BottomDetector/CollisionBottom.disabled = true
		$BottomDetector/CollisionBottom2.disabled = true
		$InsideDetector.collision_layer = 0
		$InsideDetector.collision_mask = 0
		$Sprite.material.set_shader_param('mixing', false)
		colDisabled = true

	dead_counter += 1 * Global.get_delta(delta)
	$Sprite.set_animation('Dead')
	velocity.x = 0
	
	velocity.y += 25 * Global.get_delta(delta)
	
	if shield_counter > 0:
		$Sprite.visible = true
		shield_counter = 0

	if dead_counter < 24:
		velocity.y = 0
	elif not dead_hasJumped:
		dead_hasJumped = true
		velocity.y = -550
		
	$Sprite.position += Vector2(0, velocity.y * delta)

	if dead_counter > 180:
		if Global.lives > 0 and not dead_gameover:
			Global._reset()
		elif not dead_gameover:
			MusicPlayer.play_file(MusicPlayer.mus_gameover)
			MusicPlayer.stop_on_pause()
			if Global.HUD.has_method('on_game_over'):
				Global.HUD.on_game_over()
			dead_gameover = true
		if dead_gameover:
# warning-ignore:return_value_discarded
			get_tree().create_timer( 5.0, false ).connect('timeout', self, '_game_over_screen')

func _game_over_screen():
	Global.popup = Global.popup_node.instance()
	var gameovercont = gameovercont_node.instance()
	GlobalViewport.vp.add_child(Global.popup)
	Global.popup.add_child(gameovercont)
	MusicPlayer.play_on_pause()

	get_tree().paused = true

func movement_default(delta) -> void:
	if Global.is_mario_collide_area_group('InsideDetector', 'Water'):
		movement_type = Movement.SWIMMING
	
	if velocity.y < 550 and !is_on_floor():
		if Input.is_action_pressed('mario_jump') and !Input.is_action_pressed('mario_crouch') and velocity.y < 0 and controls_enabled:
			if abs(velocity.x) < 1:
				velocity.y -= 20 * Global.get_delta(delta)
			else:
				velocity.y -= 25 * Global.get_delta(delta)
		velocity.y += 50 * Global.get_delta(delta)
	
	if velocity.x > 0:
		velocity.x -= 5 * Global.get_delta(delta)
	if velocity.x < 0:
		velocity.x += 5 * Global.get_delta(delta)

	if velocity.x > -10 * Global.get_delta(delta) and velocity.x < 10 * Global.get_delta(delta):
		velocity.x = 0

	if velocity.y > 0:
		jump_counter = 1

	if is_on_floor() and jump_internal_counter > 3:
		jump_counter = 0
	
	# Start climbing
	if Input.is_action_pressed('mario_up') || (Input.is_action_pressed('mario_crouch') && !is_on_floor()) and controls_enabled:
		if crouch || !is_over_vine(): return
		if movement_type == Movement.DEFAULT:
			movement_type = Movement.CLIMBING

func movement_swimming(delta) -> void:
	if animation_enabled:
		animate_swimming(delta, Input.is_action_just_pressed('mario_jump') and !crouch and !Input.is_action_pressed('mario_crouch'))
	
	if velocity.x > 0:
		velocity.x -= 5 * Global.get_delta(delta)
	if velocity.x < 0:
		velocity.x += 5 * Global.get_delta(delta)
	
	#Water restrictions
	if velocity.x > 175:
		velocity.x -= 15 * Global.get_delta(delta)
	if velocity.x < -175:
		velocity.x += 15 * Global.get_delta(delta)

	if velocity.x > -10 * Global.get_delta(delta) and velocity.x < 10 * Global.get_delta(delta):
		velocity.x = 0
	
	if velocity.y < 165:
		velocity.y += 5 * Global.get_delta(delta)
	
	if velocity.y > 165 + (50 * Global.get_delta(delta)):
		velocity.y -= 50 * Global.get_delta(delta)
	elif velocity.y > 165:
		velocity.y = 165
	
	if Input.is_action_just_pressed('mario_jump') and !crouch and !Input.is_action_pressed('mario_crouch') and controls_enabled:
		jump()
		
	# Start climbing
	if Input.is_action_pressed('mario_up') || (Input.is_action_pressed('mario_crouch') && !is_on_floor()) and controls_enabled:
		if crouch || !is_over_vine(): return
		if movement_type == Movement.SWIMMING:
			movement_type = Movement.CLIMBING
	
	if !Global.is_mario_collide_area_group('InsideDetector', 'Water'):
		movement_type = Movement.DEFAULT

	if can_jump: can_jump = false

func movement_climbing(delta) -> void:
	if animation_enabled: animate_climbing(delta)
	
	if !is_over_vine():
		var overlaps = $BottomDetector.get_overlapping_areas()
		for c in overlaps:
			if c.is_in_group('Climbable'):
				position.y -= velocity.y / 50 * Global.get_delta(delta)
				velocity.y = 0
				return
		movement_type = Movement.DEFAULT if !Global.is_mario_collide_area_group('InsideDetector', 'Water') else Movement.SWIMMING
		
func is_over_vine() -> bool:
	var overlaps = get_node('InsideDetector').get_overlapping_areas()
	for c in overlaps:
		if c.is_in_group('Climbable'):
			return true
	return false

func jump() -> void:
	emit_signal('jumped')
	prelanding = false
	jump_counter = 1
	can_jump = false
	jump_internal_counter = 0
	if movement_type != Movement.SWIMMING:
		velocity.y = -700 # 650
		$BaseSounds/MAIN_Jump.play()
	else:
		velocity.y = -161.5 if Global.is_mario_collide_area_group('TopWaterDetector', 'Water') else -484.5
		$BaseSounds/MAIN_Swim.play()

func enemy_stomp() -> void:
	prelanding = false
	jump_counter = 1
	can_jump = false
	jump_internal_counter = 0
	if Input.is_action_pressed('mario_jump'):
		Global.Mario.velocity.y = -700
	else:
		Global.Mario.velocity.y = -500

func controls(delta) -> void:
	if (
		Input.is_action_just_pressed('mario_jump') and
		not Input.is_action_pressed('mario_crouch') and
		not crouch and
		movement_type != Movement.SWIMMING
	):
		can_jump = true
	if not Input.is_action_pressed('mario_jump'):
		can_jump = false

	if jump_counter == 0 and can_jump and movement_type != Movement.SWIMMING:
		jump()
	
	if movement_type == Movement.CLIMBING:
		if Input.is_action_pressed('mario_up'):
			velocity.y = -125
		if Input.is_action_pressed('mario_left'):
			velocity.x = -125
		if Input.is_action_pressed('mario_right'):
			velocity.x = 125
		
		if !Input.is_action_pressed('mario_crouch') and !Input.is_action_pressed('mario_up'):
			velocity.y = 0
		if !Input.is_action_pressed('mario_left') and !Input.is_action_pressed('mario_right'):
			velocity.x = 0
		if Input.is_action_pressed('mario_crouch'):
			if is_on_floor():
				movement_type = Movement.DEFAULT
			else:
				velocity.y = 150
		elif Input.is_action_just_pressed('mario_jump'):
			movement_type = Movement.DEFAULT
			jump_counter = 0
			jump()
		return


	if velocity.y > 0.5 and not is_over_backdrop($BottomDetector, false):
		prelanding = false

	if is_on_floor() and Global.state > 0:
		if Input.is_action_pressed('mario_crouch'):
			crouch = true
			is_stuck = false
			velocity.y = 1
			if velocity.x > 0:
				velocity.x -= 6.25 * Global.get_delta(delta) if !Input.is_action_pressed('mario_right') else 2.5 * Global.get_delta(delta)
			if velocity.x < 0:
				velocity.x += 6.25 * Global.get_delta(delta) if !Input.is_action_pressed('mario_left') else 2.5 * Global.get_delta(delta)
		else:
			if !test_move(global_transform, Vector2(0, -6).rotated(global_rotation)) or ignore_stuck:
				crouch = false
				is_stuck = false
			elif !ignore_stuck:
				is_stuck = true
				velocity = Vector2.DOWN
	else:
		if !test_move(global_transform, Vector2(0, -6).rotated(global_rotation)):
			crouch = false
			is_stuck = false
		elif velocity.y >= 500 && !$InsideDetector/CollisionBig.disabled && !is_stuck:
			$InsideDetector/CollisionBig.disabled = true
			$InsideDetector/CollisionSmall.disabled = false
			crouch = true
			is_stuck = true
			velocity.y = 500
			position += Vector2(0, 32).rotated(rotation) * Global.get_delta(delta)

	if Global.state == 0:
		crouch = false
		is_stuck = false

	
	if is_stuck:
		var collisions = $TopWaterDetector.get_overlapping_bodies()
		for collider in collisions:
			if collider.has_method('hit'):
				collider.hit()
		
		var left_collide: bool = test_move(Transform2D(rotation, position + Vector2(-16, 0).rotated(rotation)), Vector2(0, -6).rotated(rotation))
		var right_collide: bool = test_move(Transform2D(rotation, position + Vector2(16, 0).rotated(rotation)), Vector2(0, -6).rotated(rotation))
		if left_collide and right_collide:
			position += Vector2(1, 0).rotated(rotation) * Global.get_delta(delta) if $Sprite.flip_h else Vector2(-1, 0).rotated(rotation) * Global.get_delta(delta)
		if left_collide and !right_collide:
			position += Vector2(1, 0).rotated(rotation) * Global.get_delta(delta)
		if right_collide and !left_collide:
			position += Vector2(-1, 0).rotated(rotation) * Global.get_delta(delta)

	if Input.is_action_pressed('mario_right') and not crouch:
		if velocity.x > -20 and velocity.x < 20:
			velocity.x = 40
		elif velocity.x <= -20:
			velocity.x += 20 * Global.get_delta(delta)
		elif velocity.x < 175 and (not Input.is_action_pressed('mario_fire') or movement_type == Movement.SWIMMING):
			velocity.x += 12.5 * Global.get_delta(delta)
		elif velocity.x < 350 and Input.is_action_pressed('mario_fire') and movement_type != Movement.SWIMMING:
			velocity.x += 12.5 * Global.get_delta(delta)

	if Input.is_action_pressed('mario_left') and not crouch:
		if velocity.x > -20 and velocity.x < 20:
			velocity.x = -40
		elif velocity.x >= 20:
			velocity.x -= 20 * Global.get_delta(delta)
		elif velocity.x > -175 and (not Input.is_action_pressed('mario_fire') or movement_type == Movement.SWIMMING):
			velocity.x -= 12.5 * Global.get_delta(delta)
		elif velocity.x > -350 and Input.is_action_pressed('mario_fire') and movement_type != Movement.SWIMMING:
			velocity.x -= 12.5 * Global.get_delta(delta)

	if Input.is_action_just_pressed('mario_fire') and not crouch and Global.state > 1:
		if Global.state in ready_powerup_scripts and ready_powerup_scripts[Global.state].has_method('do_action'):
			ready_powerup_scripts[Global.state].do_action(self)

func animate_default(delta) -> void:
	if velocity.x <= -8 * Global.get_delta(delta):
		$Sprite.flip_h = true
	if velocity.x >= 8 * Global.get_delta(delta):
		$Sprite.flip_h = false

	if appear_counter > 0:
		if not allow_custom_animation:
			if not $Sprite.animation == 'Appearing':
				animate_sprite('Appearing')
			$Sprite.speed_scale = 1
			
		appear_counter -= 1.5 * Global.get_delta(delta)
		if not shield_star: return
	if appear_counter < 0:
		appear_counter = 0

	if shield_counter > 0:
		shield_counter -= 1.5 * Global.get_delta(delta)
		if appear_counter == 0 and not shield_star:
			$Sprite.visible = int(shield_counter / 2) % 2 == 0
		if appear_counter > 0: return
	if shield_counter < 0:
		shield_counter = 0
		$Sprite.visible = true
#	$Sprite.offset.y = $Sprite.texture.get_size()

	if allow_custom_animation: return

	if launch_counter > 0:
		if $Sprite.frames.has_animation('Launching'):
			animate_sprite('Launching')
		launch_counter -= 1.01 * Global.get_delta(delta)
		return

	if crouch and not is_stuck:
		if $Sprite.frames.has_animation('Crouching'):
			animate_sprite('Crouching')
		else:
			animate_sprite('Stopped')
		return

	if not is_on_floor() and not is_over_platform() and abs(velocity.y) > 2:
		animate_sprite('Jumping')
	elif abs(velocity.x) < 0.08 and is_on_floor():
		animate_sprite('Stopped')

	if velocity.x <= -0.16 * Global.get_delta(delta):
		if is_on_floor() or $Sprite.animation == 'Launching':
			animate_sprite('Walking')

	if velocity.x >= 0.16 * Global.get_delta(delta):
		if is_on_floor() or $Sprite.animation == 'Launching':
			animate_sprite('Walking')

	if $Sprite.animation == 'Walking':
		$Sprite.speed_scale = abs(velocity.x / 50) * 2.5 + 4

func animate_swimming(delta, start) -> void:
	if start or (!start and $Sprite.animation != 'SwimmingLoop' and $Sprite.animation != 'SwimmingStart' and !is_on_floor()) and $Sprite.animation != 'Appearing':
		$Sprite.animation = 'SwimmingStart'
		$Sprite.frame = 0
		$Sprite.speed_scale = 1
	
	if $Sprite.frame > 5:
		$Sprite.animation = 'SwimmingLoop'
		$Sprite.frame = 0
		$Sprite.speed_scale = 2
	
	if velocity.x <= -8 * Global.get_delta(delta):
		$Sprite.flip_h = true
	if velocity.x >= 8 * Global.get_delta(delta):
		$Sprite.flip_h = false
		
	if launch_counter > 0:
		launch_counter -= 1.01 * Global.get_delta(delta)
	
	if appear_counter > 0:
		if not allow_custom_animation:
			if not $Sprite.animation == 'Appearing':
				animate_sprite('Appearing')
			$Sprite.speed_scale = 1
			
		appear_counter -= 1.5 * Global.get_delta(delta)
		if not shield_star: return
	if appear_counter < 0:
		appear_counter = 0
		$Sprite.animation = 'SwimmingStart'
		$Sprite.frame = 0
		$Sprite.speed_scale = 1

	if shield_counter > 0:
		shield_counter -= 1.5 * Global.get_delta(delta)
		if appear_counter == 0 and not shield_star:
			$Sprite.visible = int(shield_counter / 2) % 2 == 0
		if appear_counter > 0: return
	if shield_counter < 0:
		shield_counter = 0
		$Sprite.visible = true

	if allow_custom_animation: allow_custom_animation = false

	if crouch and not is_stuck:
		if $Sprite.frames.has_animation('Crouching'):
			animate_sprite('Crouching')
		else:
			animate_sprite('Stopped')
		return
	
	if $Sprite.animation == 'Walking':
		$Sprite.speed_scale = abs(velocity.x / 50) * 2.5 + 4
	
	if velocity.x <= -0.16 * Global.get_delta(delta):
		if (is_on_floor() or $Sprite.animation == 'Launching') and $Sprite.animation != 'Appearing':
			animate_sprite('Walking')

	if velocity.x >= 0.16 * Global.get_delta(delta):
		if (is_on_floor() or $Sprite.animation == 'Launching') and $Sprite.animation != 'Appearing':
			animate_sprite('Walking')

	if abs(velocity.x) < 0.08 and (is_on_floor() or is_over_platform()) and $Sprite.animation != 'Appearing' and $Sprite.animation != 'Launching':
		animate_sprite('Stopped')

func animate_climbing(delta) -> void:
	if velocity.x <= -8 * Global.get_delta(delta):
		$Sprite.flip_h = true
	if velocity.x >= 8 * Global.get_delta(delta):
		$Sprite.flip_h = false

	if appear_counter > 0:
		if not allow_custom_animation:
			if not $Sprite.animation == 'Appearing':
				animate_sprite('Appearing')
			$Sprite.speed_scale = 1
			
		appear_counter -= 1.5 * Global.get_delta(delta)
		return
	if appear_counter < 0:
		appear_counter = 0

	if shield_counter > 0:
		shield_counter -= 1.5 * Global.get_delta(delta)
		if appear_counter == 0 and not shield_star:
			$Sprite.visible = int(shield_counter / 2) % 2 == 0
	if shield_counter < 0:
		shield_counter = 0
		$Sprite.visible = true

	if allow_custom_animation: return

	if launch_counter > 0:
		launch_counter -= 1.01 * Global.get_delta(delta)
	
	if $Sprite.animation == 'Climbing':
		$Sprite.speed_scale = 2 if abs(velocity.y) + abs(velocity.x) > 5 else 0
	else:
		animate_sprite('Climbing')

func animate_shoe(delta) -> void:
	if velocity.x <= -8 * Global.get_delta(delta):
		$Sprite.flip_h = true
	if velocity.x >= 8 * Global.get_delta(delta):
		$Sprite.flip_h = false

	if appear_counter > 0:
		if not allow_custom_animation:
			if not $Sprite.animation == 'Appearing':
				animate_sprite('Appearing')
			$Sprite.speed_scale = 1
			
		appear_counter -= 1.5 * Global.get_delta(delta)
	if appear_counter < 0:
		appear_counter = 0

	if shield_counter > 0:
		shield_counter -= 1.5 * Global.get_delta(delta)
		if appear_counter == 0:
			$Sprite.visible = int(shield_counter / 2) % 2 == 0
	if shield_counter < 0:
		shield_counter = 0
		$Sprite.visible = true
	
	# Moving animation
	if (velocity.x <= -0.16 * Global.get_delta(delta) or velocity.x >= 0.16 * Global.get_delta(delta)) and (
	is_on_floor() or $Sprite.animation == 'Launching'):
		if !$AnimationPlayer.is_playing():
			$AnimationPlayer.queue('Small' if Global.state == 0 else 'Big')
	#else:
	#	$AnimationPlayer.stop(true)
	
	animate_sprite('Stopped')

func bind_shoe(id: int):
	shoe_node = instance_from_id(id)
	shoe_type = shoe_node.type
	Global.shoe_type = shoe_type
	is_in_shoe = true
	shoe_node.is_free = false
	$AnimationPlayer.play('Small' if Global.state == 0 else 'Big')
	shoe_node.z_index = 11

func unbind_shoe():
	shoe_node = null
	Global.shoe_type = 0
	is_in_shoe = false
	$AnimationPlayer.play('RESET')
	$AnimationPlayer.stop()
	$Sprite.position = Vector2.ZERO

func animate_sprite(anim_name) -> void:
	if $Sprite.frames.has_animation(anim_name):
		$Sprite.set_animation(anim_name)

func update_collisions() -> void:
	var is_small: bool = (Global.state > 0 && !crouch)
	$Collision.disabled = is_small
	$TopDetector/CollisionTop.disabled = is_small
	$InsideDetector/CollisionSmall.disabled = is_small
	$SmallRightDetector/CollisionSmallRight.disabled = is_small
	$SmallLeftDetector/CollisionSmallLeft.disabled = is_small
	
	$CollisionBig.disabled = !is_small && !(Global.state == 0 && is_in_shoe)
	$TopDetector/CollisionTopBig.disabled = !(Global.state > 0 && (!crouch || is_stuck)) && !(Global.state == 0 && is_in_shoe)
	$InsideDetector/CollisionBig.disabled = !is_small
	$SmallRightDetector/CollisionSmallRightBig.disabled = !is_small
	$SmallLeftDetector/CollisionSmallLeftBig.disabled = !is_small
	if is_big_collision != $TopDetector/CollisionTopBig.disabled:
		return
	else:
		is_big_collision = not $TopDetector/CollisionTopBig.disabled

# Correction while jumping upwards like in original Mario games (exclusive feature)
func vertical_correction(amount: int):
	if velocity.y >= 0: return
	
	var delta = get_physics_process_delta_time()
	var collide = move_and_collide(Vector2(0, velocity.y * delta).rotated(rotation), true, true, true)
	
	if not collide: return
	if not ('collider' in collide): return
	if 'visible' in collide.collider and collide.collider.visible == false: return
	
	var normal = collide.normal.rotated(-rotation)
	if abs(normal.x) >= 0.4: return
	
	for i in range(1, amount + 1):
		for j in [-1.0, 1.0]:
			if !test_move(
				global_transform.translated(Vector2(i * j, 0)),
				Vector2(0, velocity.y * delta).rotated(rotation)
			):
				translate(Vector2(i * j, 0).rotated(rotation))
				if velocity.x * j < 0: velocity.x = 0
				return

# One tile gap runover
func horizontal_correction(amount: int):
	if is_on_floor(): return
	if velocity.y <= 0 or abs(velocity.x) <= 1: return
	
	var delta = get_physics_process_delta_time()
	var collide = move_and_collide(Vector2(velocity.x * delta, 0).rotated(rotation), true, true, true)
	
	if not collide: return
	if not ('collider' in collide): return
	if 'visible' in collide.collider and collide.collider.visible == false: return
	
	var normal = collide.normal.rotated(-rotation)
	if not abs(normal.x) == 1: return
	if abs(normal.y) >= 0.1: return
		
	for i in range(1, amount + 1):
		for j in [-1.0, 0]:
			if !test_move(
				global_transform.translated(Vector2(0, i * j)),
				Vector2(velocity.x * delta, 0).rotated(rotation)
			):
				translate(Vector2(0, i * j).rotated(rotation))
				if velocity.y * j < 0: velocity.y = 0
				return

func fix_velocity_y(delta) -> void:
	var coll = move_and_collide(
		Vector2(velocity.x * delta, 50).rotated(rotation),
		true,
		true,
		true
	)

	if !coll: return
	if !is_on_floor() or velocity.y > -1: return
	if !('normal' in coll): return
	var normal = coll.normal.rotated(-rotation)
	#prints(coll.normal, ' and ', normal)
	if (normal.x >= 0 and velocity.x > 1) or (normal.x <= 0 and velocity.x < -1):
		velocity.y = 0
	elif (
		is_zero_approx(normal.x)
		and is_equal_approx(normal.y, -1)
	):
		velocity.y = 0

func kill() -> void:
	dead = true
	$Sprite.visible = true

func unkill() -> void:
	dead = false
	$Collision.disabled = false
	$CollisionBig.disabled = false
	$BottomDetector/CollisionBottom.disabled = false
	$BottomDetector/CollisionBottom2.disabled = false
	$InsideDetector.collision_layer = 3
	$InsideDetector.collision_mask = 3
	dead_counter = 0
	dead_hasJumped = false
	appear_counter = 0
	shield_counter = 0
	controls_enabled = true
	$TopDetector/CollisionTop.disabled = false
	$TopWaterDetector/Collision.disabled = false
	$BottomDetector/CollisionBottom.disabled = false
	$Sprite.position = Vector2.ZERO
	animate_sprite('Stopped')
	if Global.music_loader:
		Global.music_loader.play()
		MusicPlayer.play_on_pause()

func star_logic() -> void:
	var overlaps = $InsideDetector.get_overlapping_bodies()

	if overlaps.size() > 0:
		for i in overlaps:
			if i.is_in_group('Enemy') and i.has_method('kill'):
				if i.invincible: return
				if i.has_meta('starman_exception'): return
				i.kill(AliveObject.DEATH_TYPE.FALL if !i.force_death_type else i.death_type, star_kill_count)
				i.set_meta('starman_exception', true)
				if star_kill_count < 6:
					star_kill_count += 1
				else:
					star_kill_count = 0

func debug() -> void:
	if Input.is_action_just_pressed('mouse_middle'):
		$DebugText.visible = !$DebugText.visible

	$DebugText.text = 'x = ' + str(position.x) + '\ny = ' + str(position.y) + '\nx speed = ' + str(velocity.x) + '\ny speed = ' + str(velocity.y) + '\nanimation: ' + str($Sprite.animation).to_lower() + '\nmovement: ' + str(Movement.keys()[movement_type].to_lower()) + '\nfps: ' + str(Engine.get_frames_per_second())

func _process_debug_fly(delta: float) -> void:
	var debugspeed: int = 10 + (int(Input.is_action_pressed('mario_fire')) * 10) - (int( Input.is_action_pressed('debug_shift') ) * 9)
	if Input.is_action_pressed('mario_right'):
		position += Vector2(debugspeed * Global.get_delta(delta), 0).rotated(rotation)
	if Input.is_action_pressed('mario_left'):
		position -= Vector2(debugspeed * Global.get_delta(delta), 0).rotated(rotation)
	
	if Input.is_action_pressed('mario_up'):
		position -= Vector2(0, debugspeed * Global.get_delta(delta)).rotated(rotation)
	if Input.is_action_pressed('mario_crouch'):
		position += Vector2(0, debugspeed * Global.get_delta(delta)).rotated(rotation)
		
	if Input.is_action_just_pressed('debug_rotate_right'):
		target_gravity_angle += 45
		
	if Input.is_action_just_pressed('debug_rotate_left'):
		target_gravity_angle -= 45

func _process_camera(delta: float) -> void:
	if dead: return
	var camera = Global.current_camera
	if !camera: return
	
	if sections_scroll:
		var base_y = max(0, floor((position.y + 240) / 960) * 960)
		camera.limit_top = base_y
		camera.limit_bottom = base_y + 480
	
	if inited_camera_addon and inited_camera_addon.has_method('_process_camera'):
		inited_camera_addon._process_camera(self, delta)
	
	if 'sgr_scroll' in Global.current_scene and Global.current_scene.sgr_scroll:
		var base_x = floor(position.x / 640) * 640
		camera.limit_left = base_x
		camera.limit_right = base_x + 640
