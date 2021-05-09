extends Area2D


func _on_Coin_area_entered(area) -> void:
  if area.is_in_group('Mario'):
    Global.add_coins(1)
    Global.add_score(200)
    get_parent().get_node('HUD').get_node('CoinSound').play()
    queue_free()
