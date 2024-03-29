extends Node2D

#onready var platform = $KinematicPlatform
onready var platform = self
onready var bro = $'%AmazingBro'
onready var first_pos = platform.position
var timer: float
var triggered: bool = false
var t_counter: float = 0

var died: bool = false

func _physics_process(delta):
	timer += 0.08 * Global.get_delta(delta)
	platform.position.x = first_pos.x + 64 * cos(timer / 2)
	platform.position.y = first_pos.y + 40 * (-cos(timer))

	if is_instance_valid(bro):
		if !bro.alive:
			if !died:
				platform.call_deferred('remove_child', bro)
				get_parent().call_deferred('add_child', bro)
				bro.position = platform.position
				died = true
		else:
			bro.global_position = platform.global_position
	
