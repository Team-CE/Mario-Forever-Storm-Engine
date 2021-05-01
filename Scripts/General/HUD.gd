extends CanvasLayer

func _ready():
	_life_lose()
	_time()
	Global.connect('TimeTick',self,'_time')
	Global.connect('OnPlayerLoseLife',self,'_life_lose')

func _time() -> void:
	if Global.time == 99:
		$TimeSprite.frame = 0
	$Time.text = str(Global.time)

func _life_lose() -> void:
	$Lives.text = str(Global.lives)
