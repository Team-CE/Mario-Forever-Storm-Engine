extends CanvasLayer

func _ready():
	AnimPlayed = 0
	_life_lose()
	_time()
	Global.connect('TimeTick',self,'_time')
	Global.connect('OnPlayerLoseLife',self,'_life_lose')

func _time() -> void:
	if Global.time == 99:
		$TimeSprite.playing = true
	$Time.text = str(Global.time)

func _life_lose() -> void:
	$Lives.text = str(Global.lives)

var AnimPlayed : int

func _on_anim_finish():
	if AnimPlayed < 5:
		$TimeSprite.play("default")
		AnimPlayed += 1
	else:
		$TimeSprite.playing = false
