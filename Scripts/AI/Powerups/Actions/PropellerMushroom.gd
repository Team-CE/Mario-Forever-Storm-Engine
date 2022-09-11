var counter: float = 180
var gravaup: float = 10
var posy: float = -99999

func _process_movement(brain, delta):
	if posy == -99999:
		posy = brain.owner.position.y
		
	if gravaup > 0:
		gravaup -= 0.2 * Global.get_delta(delta)
		posy -= gravaup / 2 * Global.get_delta(delta)
	elif not gravaup == 0:
		gravaup = 0
	
	brain.owner.position.y = posy + sin(counter) * 12
	brain.owner.velocity.y = 0
	counter += 0.03 * Global.get_delta(delta)
