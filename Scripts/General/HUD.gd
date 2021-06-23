extends CanvasLayer


func _ready() -> void:
  Global.HUD = self
  AnimPlayed = 0
  $Coins.text = str(Global.coins)
  $Score.text = str(Global.score)
  $Lives.text = str(Global.lives)
  Global.connect('TimeTick', self, '_time')
  Global.connect('OnPlayerLoseLife', self, '_life_lose')
  $GameoverSprite.visible = false

func _time() -> void:
  if Global.time == 99 and not Global.level_ended:
    $TimeSprite.playing = true
    $TimeoutSound.play()
  $Time.text = str(Global.time)

func _life_lose() -> void:
  print('Died!')

var AnimPlayed : int


func _on_anim_finish() -> void:
  if AnimPlayed < 5:
    $TimeSprite.play('default')
    AnimPlayed += 1
  else:
    $TimeSprite.playing = false
