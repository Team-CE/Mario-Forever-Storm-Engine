extends Area2D


func _on_area_entered(area):
	if area.name == 'InsideDetector':
		Global._pll()
