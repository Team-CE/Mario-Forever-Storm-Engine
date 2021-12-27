extends CanvasLayer

export var active: bool = true

func _ready() -> void:
  Global.HUD = self

  if not active:
    self.scale = Vector2.ZERO
    queue_free()
  
  AnimPlayed = 0
  $Coins.text = str(Global.coins)
  $Score.text = str(Global.score)
  $Lives.text = str(Global.lives)
# warning-ignore:return_value_discarded
  Global.connect('TimeTick', self, '_time')
# warning-ignore:return_value_discarded
  Global.connect('OnPlayerLoseLife', self, '_life_lose')
  $GameoverSprite.visible = false
    
func _process(_delta: float) -> void:
  $DebugFlySprite.visible = Global.debug_fly
  $DebugInvisibleSprite.visible = Global.debug_inv

func _time() -> void:
  if Global.time == 99 and not Global.level_ended:
    $TimeSprite.playing = true
    $TimeoutSound.play()
  $Time.text = str(abs(Global.time))

func _life_lose() -> void:
  print('Died!')

var AnimPlayed : int


func _on_anim_finish() -> void:
  if AnimPlayed < 5:
    $TimeSprite.play('default')
    AnimPlayed += 1
  else:
    $TimeSprite.playing = false
