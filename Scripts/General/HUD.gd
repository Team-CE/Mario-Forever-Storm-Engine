extends CanvasLayer

var straycount: int
export var active: bool = true

func _ready() -> void:
	Global.HUD = self

	if not active:
		visible = false
		queue_free()
	
	AnimPlayed = 0
	$Coins.text = str(Global.coins)
	$Score.text = str(Global.score)
	$Lives.text = str(Global.lives)
	$Collectibles/Counter.text = str(Global.collectibles + int(Global.collectible_saved))
	if Global.collectibles + int(Global.collectible_saved) > 0:
		$Collectibles.modulate.a = 1
	$DebugOrphaneNodes.visible = false
# warning-ignore:return_value_discarded
	Global.connect('TimeTick', self, '_time')
# warning-ignore:return_value_discarded
	Global.connect('OnPlayerLoseLife', self, '_life_lose')
		
func _physics_process(_delta: float) -> void:
	
	if Global.debug:
		$DebugFlySprite.visible = Global.debug_fly
		$DebugInvisibleSprite.visible = Global.debug_inv
# warning-ignore:narrowing_conversion
		straycount = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
		$DebugOrphaneNodes.visible = true if straycount > 0 else false
		$DebugOrphaneNodes.text = str(straycount)

func _time() -> void:
	if Global.time == 99 and not Global.level_ended and visible:
		$TimeSprite.playing = true
		$TimeoutSound.play()
	$Time.text = str(abs(Global.time))
	if Global.time <= 0 and not $GameoverText.visible:
# warning-ignore:return_value_discarded
		get_tree().create_timer(1.2, false).connect('timeout', self, 'on_timeout')
		$GameoverText.text = 'time up!'
		$GameoverText.rect_position.y = -32
		$GameoverText.visible = true

func _life_lose() -> void:
	print('Died!')

var AnimPlayed : int


func _on_anim_finish() -> void:
	if AnimPlayed < 5:
		$TimeSprite.play('default')
		AnimPlayed += 1
	else:
		$TimeSprite.playing = false

func on_game_over() -> void:
	$GameoverText.text = 'game over'
	$GameoverText.rect_position.y = 224
	$GameoverText.visible = true

func on_timeout() -> void:
# warning-ignore:return_value_discarded
	get_tree().create_tween().tween_property($GameoverText, 'rect_position:y', 224.0, 0.3)
