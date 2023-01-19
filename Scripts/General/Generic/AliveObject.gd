extends KinematicBody2D
class_name AliveObject, "res://GFX/Editor/AliveBody.png"

signal enemy_died

const multiplier_scores = [1, 2, 5, 10, 20, 50, 0.01]
const pitch_md = [1, 1.1, 1.25, 1.4, 1.6, 1.8, 2]

enum DEATH_TYPE {
	BASIC,
	FALL,
	CUSTOM,
	NONE,
	DISAPPEAR,
	UNFREEZE
}

export var vars: Dictionary = {"speed":50.0}
export var AI: Script

export var gravity_scale: float = 1
export var score: int = 100
export var smart_turn: bool
export var invincible: bool
export var invincible_for_projectiles: Array = []
export var invincible_for_shells: bool = false
export(float,-1,1) var dir: float = -1
export var can_freeze: bool = false
export var frozen: bool = false
export var force_death_type: bool = false
export var auto_destroy: bool = true
export var death_signal_exception: bool = false

#RayCasts leave empty if smart_turn = false
export var ray_L_pth: NodePath
export var ray_R_pth: NodePath
export var sound_pth: NodePath
export var alt_sound_pth: NodePath
export var animated_sprite_pth: NodePath
export var frozen_sprite_pth: NodePath

export var temp: bool = false # For AnimationPlayers

var ray_L: RayCast2D
var ray_R: RayCast2D
var sound: AudioStreamPlayer2D
var alt_sound: AudioStreamPlayer2D
var animated_sprite: AnimatedSprite
var frozen_sprite: AnimatedSprite

var clipper: Control

var freeze_sound = preload('res://Sounds/Main/ice1.wav')
var unfreeze_sound = preload('res://Sounds/Main/ice2.wav')
onready var freeze_counter: float = 0
var freeze_sprite_counter: float

var velocity: Vector2
var alive: bool = true
var death_type: int
var velocity_enabled: bool = true
var animated_sprite_position: Vector2

var time: SceneTreeTimer

onready var brain: Brain = Brain.new()      # Shell for AI

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	
	if ray_L_pth.is_empty() || ray_R_pth.is_empty(): # Ray casts init
		smart_turn = false
	else:
		ray_L = get_node(ray_L_pth)
		ray_R = get_node(ray_R_pth)
	
	if !sound_pth.is_empty():	# Sound player init
		sound = get_node(sound_pth)

	if !alt_sound_pth.is_empty():	# Alt sound player init
		alt_sound = get_node(alt_sound_pth)
		
	if animated_sprite_pth.is_empty():	# Animated sprite init
		push_warning('[CE WARNING] Cannot load Animated sprite at:' + str(self))
	else:
		animated_sprite = get_node(animated_sprite_pth)
		
	if !frozen_sprite_pth.is_empty():
		frozen_sprite = get_node(frozen_sprite_pth)
		
	if can_freeze:
		var ice1 = AudioStreamPlayer2D.new()
		var ice2 = AudioStreamPlayer2D.new()
		
		ice1.stream = freeze_sound
		ice2.stream = unfreeze_sound
		ice1.bus = 'Sounds'
		ice2.bus = 'Sounds'
		
		ice2.max_distance = 600
		
		ice1.name = 'ice1'
		ice2.name = 'ice2'
		
		add_child(ice1)
		add_child(ice2)
	
	brain.name = 'Brain'	# Brain init
	add_child(brain)
	if AI != null:	# AI init
		brain.set_script(AI)
		brain._setup(self)
	else:
		printerr('[CE ERROR] AliveObject' + str(self) + ': No AI script assigned!')

	if brain.has_method('_ready_mixin'):
		brain._ready_mixin()

	if death_type == DEATH_TYPE.CUSTOM && !brain.has_method('_on_custom_death'):
		printerr('[CE ERROR] AliveObject' + str(self) + ': No custom death function provided.')
	
	if !death_signal_exception:
# warning-ignore:return_value_discarded
		connect('enemy_died', Global.current_scene, 'activate_event', ['on_enemy_death', [get_name()]])
	
	temp = false

func _physics_process(delta: float) -> void:
	if !alive && death_type != DEATH_TYPE.FALL && death_type != DEATH_TYPE.BASIC && !force_death_type:
		return
	
	brain._ai_process(delta) #Calling brain cells
	
	var camera = Global.current_camera
	
	if camera:
		if auto_destroy and (position.y > camera.limit_bottom + 32 and position.y < camera.limit_bottom + 200):
			queue_free()
	# Fixing ceiling collision and is_on_floor() flickering
	if (is_on_floor() || is_on_ceiling()) && alive && velocity.y >= 0:
		velocity.y = 1
	
	if velocity_enabled:
		if !frozen:
			velocity = move_and_slide_with_snap(velocity.rotated(rotation), (Vector2.DOWN * (8 if velocity.y >= 0 else 0)).rotated(rotation), Vector2.UP.rotated(rotation), false, 4, 0.802852, false).rotated(-rotation)
		else:
			velocity = move_and_slide_with_snap(velocity, (Vector2.DOWN * (8 if velocity.y >= 0 else 0)).rotated(rotation), Vector2.UP, false, 4, 0.802852, false)
	# Freeze
	if frozen_sprite && frozen:
		if freeze_counter < 300:
			frozen_sprite.visible = true
		frozen_sprite.playing = true
		animated_sprite.playing = false
		freeze_counter += 1 * Global.get_delta(delta)
		freeze_sprite_counter += 1 * Global.get_delta(delta)
		if freeze_sprite_counter > 80:
			freeze_sprite_counter = 0
			frozen_sprite.frame = 0
		
		if Global.is_mario_collide('TopDetector', self) and Global.Mario.is_on_floor() and not force_death_type:
# warning-ignore:return_value_discarded
			kill(DEATH_TYPE.UNFREEZE)
		
	if freeze_counter > 300:
		frozen_sprite.visible = int(freeze_counter / 2) % 2 == 0
	if freeze_counter > 360:
# warning-ignore:return_value_discarded
		kill(DEATH_TYPE.UNFREEZE)

# Useful functions
func turn(mp:float = 1) -> void:
	dir = -dir
	velocity.x = vars["speed"] * mp * dir
	animated_sprite.flip_h = dir < 0

func on_edge() -> bool:
	return (ray_L.is_colliding() && !ray_R.is_colliding()) || (ray_R.is_colliding() && !ray_L.is_colliding())

# warning-ignore:shadowed_variable
func kill(death_type: int = self.death_type, score_mp: int = 0, csound = null, projectile = null, is_shell: bool = false) -> bool:
	if invincible:
		return false
	if invincible_for_shells and is_shell:
		return false
	if projectile: 
		for proj_exception in invincible_for_projectiles:
			if proj_exception.to_lower() in projectile.to_lower():
				return false
	if not force_death_type:
		alive = false
		collision_layer = 0
		collision_mask = 0
		velocity.x = rng.randf_range(-50, 50)
		gravity_scale = 0.4
	if self.death_type != DEATH_TYPE.UNFREEZE:
		self.death_type = death_type
	if brain.has_method('_on_any_death'):
		brain._on_any_death()
		
	if !death_signal_exception: emit_signal('enemy_died')
	
	match self.death_type:			 # TEMP
		DEATH_TYPE.BASIC:
			if !csound:
				sound.play()
			else:
				csound.play()
			collision_mask = 0b10
			velocity.x = 0
			gravity_scale = 1.7
			animated_sprite.set_animation('dead')
			Global.current_scene.add_child(ScoreText.new(score, global_position))
			
			time = get_tree().create_timer(4.0, false)
# warning-ignore:return_value_discarded
			time.connect('timeout', self, 'instance_free')
			return true
		DEATH_TYPE.DISAPPEAR:
			queue_free()
			return true
		DEATH_TYPE.FALL:
			if !csound:
				alt_sound.play()
				alt_sound.pitch_scale = pitch_md[score_mp]
			else:
				csound.play()
				csound.pitch_scale = pitch_md[score_mp]
			if score_mp > len(multiplier_scores) - 1:
				score_mp = 0
			if score_mp == 6:
				Global.add_lives(1, false)
			Global.current_scene.add_child(ScoreText.new((score if !is_shell else 100) * multiplier_scores[score_mp], global_position))
			z_index = 10
			velocity.y = -180
			rotation = Global.Mario.rotation
			animated_sprite.set_animation('falling')
#			if visen != null:
#				visen.set_enabler(VisibilityEnabler2D.ENABLER_PARENT_PROCESS, false)
#				visen.set_enabler(VisibilityEnabler2D.ENABLER_PARENT_PHYSICS_PROCESS, false)

			time = get_tree().create_timer(4.0, false)
# warning-ignore:return_value_discarded
			time.connect('timeout', self, 'instance_free')
			return true
		DEATH_TYPE.CUSTOM:
			if brain.has_method('_on_custom_death'):
				brain._on_custom_death(score_mp)
			return true
		DEATH_TYPE.UNFREEZE:
			visible = false
			if has_node('Collision'): $Collision.set_deferred('disabled', true)
			if has_node('CollisionShape2D'): $CollisionShape2D.set_deferred('disabled', true)
			if has_node('KillDetector/Collision'): $KillDetector/Collision.set_deferred('disabled', true)
			$ice2.play()
			var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
			for i in 4:
				var debris_effect = BrickEffect.new(position + Vector2(0, -16).rotated(rotation), speeds[i], frozen_sprite.frames)
				get_parent().add_child(debris_effect)
			time = get_tree().create_timer(2.0, false)
# warning-ignore:return_value_discarded
			time.connect('timeout', self, 'instance_free')
			return true
			
	return false
	
func freeze() -> void:
	if !can_freeze || frozen:
		return
		
	$ice1.play()
	
	if score > 0:
		Global.current_scene.add_child(ScoreText.new(score, global_position))
	
	frozen = true
	collision_layer = 0b100011
	collision_mask = 0b11
	
	death_type = DEATH_TYPE.UNFREEZE
	animated_sprite.playing = false
	
	
	# Clipping
	if !clipper:
		clipper = Control.new()
		var anim_parent: Node = animated_sprite.get_parent()
		
		anim_parent.add_child(clipper)
		anim_parent.remove_child(animated_sprite)
		clipper.add_child(animated_sprite)
		animated_sprite_pth = animated_sprite.get_path()
		
		animated_sprite_position = animated_sprite.position
		set_clipper_position(Vector2.ZERO)
		frozen_sprite.raise()
	
	clipper.rect_clip_content = true

func set_clipper_position(new) -> void:
	if not frozen_sprite or not animated_sprite:
		return
	animated_sprite.position = animated_sprite_position
	var frame_size: Vector2 = frozen_sprite.frames.get_frame(frozen_sprite.animation, frozen_sprite.frame).get_size()
	clipper.rect_size = frame_size - new
	clipper.rect_position = frozen_sprite.offset - (frame_size / 2) + frozen_sprite.position
	clipper.rect_position += new
	animated_sprite.position = -clipper.rect_position + frozen_sprite.position - animated_sprite.offset + animated_sprite_position

func instance_free():
	queue_free()

func getInfo() -> String:
	return 'name: {n}\nvel x: {x}\nvel y: {y}'.format({'x':velocity.x,'y':velocity.y,'n':self.get_name()}).to_lower()

