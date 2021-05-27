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

enum VISIBILITY_TYPE {
  VISIBLE,
  INVIS_ONCE,
  INVIS_ALWAYS
}

export(BONUS_TYPE) var bonus_type: int = BONUS_TYPE.COIN

export(VISIBILITY_TYPE) var visibility: int = VISIBILITY_TYPE.VISIBLE

var active: bool = true
var triggered: bool = false
var t_counter: float = 0
var coin_counter: float = 0

var initial_position: Vector2

func _ready() -> void:
  if not visibility == VISIBILITY_TYPE.VISIBLE:
    visible = false
  if bonus_type == BONUS_TYPE.BRICK or bonus_type == BONUS_TYPE.COIN_BRICK:
    $Sprite.animation = 'Brick'
  initial_position = position

func _process(delta) -> void:
  if active:
    _process_active()

  if triggered:
    _process_trigger(delta)
  
  if coin_counter >= 1 and coin_counter <= 6:
    coin_counter += 0.02 * Global.get_delta(delta)

func _process_active() -> void:
  var mario = get_parent().get_node('Mario')
  var mario_td = mario.get_node('TopDetector')
  var td_overlaps = mario_td.get_overlapping_bodies()

  if td_overlaps and td_overlaps.has(self) and mario.y_speed <= 0.01 and not mario.standing:
    active = false
    if bonus_type != BONUS_TYPE.BRICK and bonus_type != BONUS_TYPE.COIN_BRICK:
      $Sprite.set_animation('Empty')
    triggered = true
    visible = true
    match bonus_type:
      BONUS_TYPE.COIN:
        Global.play_base_sound('MAIN_Coin')
        Global.add_coins(1)

        var coin_effect = CoinEffect.new(position + Vector2(0, -32))
        get_parent().add_child(coin_effect)
              
      BONUS_TYPE.FLOWER:
        var powerup = load('res://Objects/Bonuses/Powerup.tscn').instance()
        powerup.position = position
        if Global.state == 0:
          powerup.type = powerup.POWERUP_TYPE.MUSHROOM
        else:
          powerup.type = powerup.POWERUP_TYPE.FLOWER
        get_parent().add_child(powerup)
        Global.play_base_sound('MAIN_PowerupGrow')
      
      BONUS_TYPE.BRICK:
        if Global.state == 0:
          Global.play_base_sound('MAIN_Bump')
        else:
          brick_break()
      
      BONUS_TYPE.COIN_BRICK:
        if coin_counter == 0:
          coin_counter = 1
        if coin_counter <= 100:
          Global.play_base_sound('MAIN_Coin')
          Global.add_coins(1)

          var coin_effect = CoinEffect.new(position + Vector2(0, -32))
          get_parent().add_child(coin_effect)

          if coin_counter > 6:
            $Sprite.set_animation('Empty')
            coin_counter = 100
        

func brick_break():
  Global.play_base_sound('MAIN_BrickBreak')
  var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
  for i in range(4):
    var debris_effect = BrickEffect.new(position + Vector2(0, -16), speeds[i])
    get_parent().add_child(debris_effect)
  Global.add_score(50)
  queue_free()

func _process_trigger(delta) -> void:
  t_counter += (1 if t_counter < 200 else 0) * Global.get_delta(delta)
  
  if t_counter < 12:
    position.y += (-1 if t_counter < 6 else 1) * Global.get_delta(delta)
  
  if t_counter >= 12:
    position = initial_position
    if bonus_type == BONUS_TYPE.BRICK or (bonus_type == BONUS_TYPE.COIN_BRICK and $Sprite.animation == 'Brick'):
      t_counter = 0
      triggered = false
      active = true
