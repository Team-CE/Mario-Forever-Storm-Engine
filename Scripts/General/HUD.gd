extends CanvasLayer

var straycount: int
export var active: bool = true
export var visible: bool = true

func _ready() -> void:
  Global.HUD = self

  if not active:
    self.scale = Vector2.ZERO
    queue_free()
  
  AnimPlayed = 0
  $Coins.text = str(Global.coins)
  $Score.text = str(Global.score)
  $Lives.text = str(Global.lives)
  $DebugOrphaneNodes.visible = false
# warning-ignore:return_value_discarded
  Global.connect('TimeTick', self, '_time')
# warning-ignore:return_value_discarded
  Global.connect('OnPlayerLoseLife', self, '_life_lose')
  $GameoverSprite.visible = false
    
func _process(_delta: float) -> void:
  
  if Global.debug:
    $DebugFlySprite.visible = Global.debug_fly
    $DebugInvisibleSprite.visible = Global.debug_inv
# warning-ignore:narrowing_conversion
    straycount = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
    $DebugOrphaneNodes.visible = true if straycount > 0 else false
    $DebugOrphaneNodes.text = str(straycount)
  
  if not visible:
    self.scale = Vector2.ZERO
  else:
    self.scale = Vector2(1, 1)

func _time() -> void:
  if Global.time == 99 and not Global.level_ended and visible:
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
