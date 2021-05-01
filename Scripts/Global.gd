extends Node

signal TimeTick
signal OnPlayerLoseLife

var lives : int = 3
var time : int = 10
var score : int = 0

onready var timer : Timer = Timer.new() 

func _ready() -> void:
	timer.wait_time = 1.45
	add_child(timer)

func _reset(time:int = time,lives:int = lives,score:int = score) -> void:
	self.time = time
	self.lives = lives
	self.score = score

func _physics_process(delta) -> void:
	if timer.time_left <= 1 && time != -1:
		_delay()
		timer.start()

func _add_score(score:int) -> void:
	self.score += abs(score)

func _delay() -> void:
	emit_signal('TimeTick')
	time -= 1

func _pll() -> void: #Player Lose Life
	emit_signal('OnPlayerLoseLife')
	lives -= 1
