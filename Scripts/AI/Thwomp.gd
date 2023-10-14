extends Brain

var top: bool = false
var falling: bool = false

var counter: float = 50
var hit_counter: float = 0
var inv_counter: float = 10
var is_smiling: bool = false
var smile_counter: float = 0
var laugh: bool = true

var camera: Camera2D
var visi: VisibilityEnabler2D

var initial_pos: Vector2
var offset: Vector2

func _setup(b) -> void:
	._setup(b)
	initial_pos = owner.position
	owner.get_node('CollisionShape2D').disabled = true
	yield(owner.get_tree(), 'idle_frame')
	camera = Global.current_camera
	visi = owner.get_node('VisibilityNotifier2D')
# warning-ignore:return_value_discarded
	visi.connect('screen_exited',self,'_on_screen_exited')

func _ai_process(delta: float) -> void:
	._ai_process(delta)

	if Global.Mario.is_in_shoe and Global.Mario.shoe_type == 1:
		if Global.is_mario_collide_area('BottomDetector', owner.get_node('Hitbox')) and Global.Mario.velocity.y >= -1:
			inv_counter = 0
			Global.Mario.shoe_node.stomp()
			return
		elif Global.is_mario_collide_area('InsideDetector', owner.get_node('Hitbox')) and inv_counter > 8:
			if Global.Mario.shield_counter == 0:
				is_smiling = true
			Global._ppd()
	else:
		if Global.is_mario_collide_area('InsideDetector', owner.get_node('Hitbox')):
			if Global.Mario.shield_counter == 0:
				is_smiling = true
			Global._ppd()
	
	if inv_counter < 10:
		inv_counter += 1 * Global.get_delta(delta)
	
	if is_smiling:
		smile_counter += 1 * Global.get_delta(delta)
		if laugh:
			owner.alt_sound.play()
			owner.animated_sprite.animation = 'laugh'
			laugh = false
		if smile_counter > 120:
			owner.animated_sprite.animation = 'default'
			laugh = true
			is_smiling = false
			smile_counter = 0
		
	if !falling and !top:
		owner.velocity = Vector2.ZERO

	var area_overlaps = owner.get_node('Area2D').get_overlapping_bodies()
	if area_overlaps.has(Global.Mario) and !falling and !top:
		falling = true

	if falling:
		if !owner.is_on_floor(): owner.velocity += Vector2(0, 40 * owner.gravity_scale * Global.get_delta(delta))
		counter = 50
		owner.get_node('CollisionShape2D').disabled = false
		var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
		for i in range(len(g_overlaps)):
			if g_overlaps[i].has_method('hit'):
				if ('ignore hidden' in owner.vars and owner.vars['ignore hidden']) && !g_overlaps[i].visible: return
				g_overlaps[i].hit(true)
				if g_overlaps[i].qtype == QBlock.BLOCK_TYPE.BRICK:
					hit_counter = 3
				
	if hit_counter > 0:
		hit_counter -= 1 * Global.get_delta(delta)
		if camera:
			camera.set_offset(Vector2(
				rand_range(-3.0, 3.0),
				rand_range(-3.0, 3.0)
			))
		
	if hit_counter <= 0 and hit_counter > -99:
		if camera: camera.set_offset(Vector2(0, 0))
		hit_counter = -99

		
	if falling and owner.is_on_floor():
		owner.sound.play()
		owner.get_parent().add_child(Explosion.new(owner.position + owner.get_node('EffectPosition1').position.rotated(owner.rotation)))
		owner.get_parent().add_child(Explosion.new(owner.position + owner.get_node('EffectPosition2').position.rotated(owner.rotation)))
		if hit_counter <= 0:
			falling = false
			top = true
		else:
			owner.velocity = Vector2(0, 10)
		
	if top:
		owner.velocity = Vector2.ZERO
		if counter == 50:
			hit_counter = 20
			offset = (owner.position - initial_pos).rotated(-owner.rotation)
			owner.get_node('CollisionShape2D').disabled = true
			
		if counter > 0:
			counter -= 1 * Global.get_delta(delta)
			owner.position = initial_pos + offset.rotated(owner.rotation)
		
		if counter <= 0:
			if offset.y > 0:
				offset += Vector2(0, -1) * Global.get_delta(delta)
				owner.position = initial_pos + offset.rotated(owner.rotation)
			else:
				owner.position = initial_pos
				top = false
				falling = false
				if !visi.is_on_screen():
					visi.process_parent = true
					visi.physics_process_parent = true
		
	if rand_range(-70.0, 40.0) > 39.0 and not is_smiling:
		owner.animated_sprite.frame = 0
		owner.animated_sprite.playing = true


func _on_screen_exited() -> void:
	# Cut down unncesessary performance consumption
	if falling || (top && counter <= 0 && offset.y > 0):
		visi.process_parent = false
		visi.physics_process_parent = false
	else:
		visi.process_parent = true
		visi.physics_process_parent = true
