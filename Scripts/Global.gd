extends Node

var gravity: float = 10

signal TimeTick
signal OnPlayerLoseLife

var lives: int = 3
var time: int = 360
var score: int = 0
var coins: int = 0

var debug : bool = true

onready var timer : Timer = Timer.new() 

static func get_delta(delta) -> float:
	return 50 / (1 / (delta if not delta == 0 else 0.0001))

func _ready() -> void:
	if debug:
		add_child(preload("res://Objects/Core/Inspector.tscn").instance())
	timer.wait_time = 1.45
	add_child(timer)

func _reset(time: int = time, lives: int = lives) -> void:
	self.time = time
	self.lives = lives

func _physics_process(delta) -> void:
	if timer.time_left <= 1 && time != -1:
		_delay()
		timer.start()

func _add_score(score: int) -> void:
	self.score += abs(score)

func _delay() -> void:
	emit_signal('TimeTick')
	time -= 1

func _pll() -> void: #Player Lose Life
	emit_signal('OnPlayerLoseLife')
	lives -= 1
