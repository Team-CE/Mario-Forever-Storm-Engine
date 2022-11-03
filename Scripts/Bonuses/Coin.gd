extends Area2D

var appearing = false

export var frozen: bool = false
var freeze_counter: float
var freeze_sprite_counter: float

func _ready() -> void:
	if appearing:
		Global.play_base_sound('MAIN_Coin')
		Global.add_coins(1)
		var coin_effect = CoinEffect.new(position + Vector2(0, -48).rotated(rotation), rotation)
		get_parent().add_child(coin_effect)
		queue_free()
	
	if frozen:
		freeze_counter = -1
		$IceSprite.visible = true
		$IceSprite.playing = true
		$Sprite.playing = false
		$CollisionShape2D.set_deferred('disabled', true)
		$StaticBody2D/Collision2.set_deferred('disabled', false)

func _physics_process(delta) -> void:
	if frozen:
		if freeze_counter >= 0:
			freeze_counter += 1 * Global.get_delta(delta)
			
		freeze_sprite_counter += 1 * Global.get_delta(delta)
		if freeze_counter < 300:
			$IceSprite.visible = true
			
		if freeze_sprite_counter > 80:
			freeze_sprite_counter = 0
			$IceSprite.frame = 0
		
	if freeze_counter > 300:
		$IceSprite.visible = int(freeze_counter / 2) % 2 == 0
	if freeze_counter > 360:
		unfreeze()
	
	var g_overlaps = $BlockDetector.get_overlapping_bodies()
	var brick: StaticBody2D
	if (
		len(g_overlaps) > 0 and
		g_overlaps[0] is StaticBody2D and
		'triggered' in g_overlaps[0] and
		't_counter' in g_overlaps[0]
	):
		brick = g_overlaps[0]
		if !brick.is_in_group('Breakable'):
			return
		if brick.triggered and !frozen and brick.t_counter < 12:
			trigger_fly()

func trigger_fly():
	Global.add_coins(1)
	Global.add_score(200)
	Global.HUD.get_node('CoinSound').play()
	var coin_effect = CoinEffect.new(position, rotation)
	get_parent().add_child(coin_effect)
	queue_free()

func freeze(forever: bool = false) -> void:
	if forever:
		freeze_counter = -1
	frozen = true
	$IceSprite.visible = true
	$IceSprite.playing = true
	$ice1.play()
	$Sprite.playing = false
	$CollisionShape2D.set_deferred('disabled', true)
	$StaticBody2D/Collision2.set_deferred('disabled', false)

func unfreeze() -> void:
	frozen = false
	$IceSprite.visible = false
	$IceSprite.playing = false
	$ice2.play()
	$Sprite.playing = true
	$CollisionShape2D.set_deferred('disabled', false)
	$StaticBody2D/Collision2.set_deferred('disabled', true)
	
	freeze_counter = 0
	freeze_sprite_counter = 0
	var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
	for i in 4:
		var debris_effect = BrickEffect.new(position, speeds[i], $IceSprite.frames)
		get_parent().add_child(debris_effect)

func _on_Coin_area_entered(area) -> void:
	if appearing or frozen: return
	if area.is_in_group('Mario'):
		Global.add_coins(1)
		Global.add_score(200)
		Global.HUD.get_node('CoinSound').play()
		queue_free()


func _on_Coin_body_entered(body) -> void:
	if appearing: return
	if 'Iceball'.to_lower() in body.get_name().to_lower() and 'belongs' in body and !frozen:
		freeze(bool(body.belongs))
		body.explode()
	elif 'Fireball'.to_lower() in body.get_name().to_lower() and frozen:
		unfreeze()
		body.explode()
