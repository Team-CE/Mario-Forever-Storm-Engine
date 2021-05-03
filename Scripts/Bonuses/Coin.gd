extends Area2D


func _on_Coin_area_entered(area):
	if area.is_in_group('Mario'):
		Global._add_coin(1)
		Global._add_score(200)
		get_parent().get_node('HUD').get_node('CoinSound').play()
		queue_free()
