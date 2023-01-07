extends Node2D

export var wait_for_next_ejection: float = 300.0
export var launch_delay: float = 15.0
export var launch_strength: float = -10.0
export var podoboo_count: int = 8
export var lower_up_when_diagonal: bool = false # true = MFEV1.cca behaviour, false = original MF

const podo_scene = preload('res://Objects/Enemies/Podoboo.tscn')

var podo_left: int = 0
var counter2: float = 0.0
onready var counter: float = wait_for_next_ejection - 50
onready var rng = RandomNumberGenerator.new()

func _ready():
	$Sprite.free()
	rng.randomize()

func _physics_process(delta):
	if !Global.is_getting_closer(-256, position):
		return
		
	if podo_left <= 0:
		counter += Global.get_delta(delta)
	else:
		counter2 += Global.get_delta(delta)
		if counter2 > launch_delay:
			podo_left -= 1
			counter2 = 0
			
			var podo = podo_scene.instance()
			podo.global_transform = global_transform
			Global.current_scene.add_child(podo)
			podo.remove_in_lava = true
			
			podo._velocity.x = rng.randi_range(-4, 4)
			podo._velocity.y = launch_strength
			if lower_up_when_diagonal:
				podo._velocity.y += abs(podo._velocity.x) / 2
			podo.active = true
			$shoot.play()
		
	if counter > wait_for_next_ejection:
		podo_left = podoboo_count
		counter = 0

