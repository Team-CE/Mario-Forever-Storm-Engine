extends StaticBody2D

enum BONUS_TYPE {
  COIN,
  FLOWER,
  BEETROOT,
  LUI,
  POISON,
  BRICK,
  COIN_BRICK
}

export(BONUS_TYPE) var bonus_type: int = BONUS_TYPE.COIN

var active: bool = true
var triggered: bool = false
var t_counter: float = 0

func _process(delta) -> void:
  if active:
    _process_active(delta)

  if triggered:
    _process_trigger(delta)

func _process_active(delta) -> void:
  var mario = get_parent().get_node('Mario')
  var mario_td = mario.get_node('TopDetector')
  var td_overlaps = mario_td.get_overlapping_bodies()

  if td_overlaps and td_overlaps.has(self) and mario.y_speed <= 0:
    match bonus_type:
      BONUS_TYPE.COIN:
        Global.play_base_sound('MAIN_Coin')
        active = false
        $Sprite.set_animation('Empty')
        triggered = true
        Global.add_coins(1)

        var coin_effect = CoinEffect.new(position + Vector2(0, -32))
        get_parent().add_child(coin_effect)

func _process_trigger(delta) -> void:
  t_counter += (1 if t_counter < 200 else 0) * Global.get_delta(delta)
	
  if t_counter < 12:
    position.y += (-1 if t_counter < 6 else 1) * Global.get_delta(delta)
