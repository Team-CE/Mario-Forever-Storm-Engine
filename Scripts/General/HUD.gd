extends CanvasLayer

func _ready():
	AnimPlayed = 0
	_life_lose()
	_time()
	$Coins.text = str(Global.coins)
	Global.connect('TimeTick', self, '_time')
	Global.connect('OnPlayerLoseLife', self, '_life_lose')
	Global.connect('OnCoinCollected', self, '_on_coin_collected')
	Global.connect('OnScoreChange', self, '_on_score_change')

func _time() -> void:
	if Global.time == 99:
		$TimeSprite.playing = true
		$TimeoutSound.play()
	$Time.text = str(Global.time)

func _life_lose() -> void:
	$Lives.text = str(Global.lives)

var AnimPlayed : int

func _on_anim_finish():
	if AnimPlayed < 5:
		$TimeSprite.play('default')
		AnimPlayed += 1
	else:
		$TimeSprite.playing = false

func _on_coin_collected():
	if Global.coins >= 100:
		$LifeSound.play()
		var score_text = load('res://Objects/Core/ScoreText.tscn').instance()
		var mario = get_parent().get_node('Mario')
		get_parent().add_child(score_text)
		print(mario)
		score_text.position = mario.position
		score_text.position.y -= 32
		Global.coins = 0
		
	$Coins.text = str(Global.coins)

func _on_score_change():
	$Score.text = str(Global.score)
