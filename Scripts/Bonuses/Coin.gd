extends Area2D

var appearing = false

func _ready() -> void:
  if appearing:
    Global.play_base_sound('MAIN_Coin')
    Global.add_coins(1)
    var coin_effect = CoinEffect.new(position + Vector2(0, -32))
    get_parent().add_child(coin_effect)
    queue_free()

func _on_Coin_area_entered(area) -> void:
  if area.is_in_group('Mario') and not appearing:
    Global.add_coins(1)
    Global.add_score(200)
    get_parent().get_node('HUD').get_node('CoinSound').play()
    queue_free()
