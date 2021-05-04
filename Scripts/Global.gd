extends Node

var gravity: float = 10

signal TimeTick
signal OnPlayerLoseLife
signal OnScoreChange
signal OnLivesChange
signal OnCoinCollected

var lives: int = 4
var time: int = 999
var score: int = 0
var coins: int = 95

var debug: bool = true
var player_dead: bool = false

onready var timer : Timer = Timer.new()

static func get_delta(delta) -> float:
	return 50 / (1 / (delta if not delta == 0 else 0.0001))

func _ready() -> void:
	if debug:
		add_child(preload("res://Objects/Core/Inspector.tscn").instance())
	timer.wait_time = 1.45
	add_child(timer)

func _reset() -> void:
	lives -= 1
	player_dead = false

func _physics_process(delta) -> void:
	if timer.time_left <= 1 && time != -1:
		_delay()
		timer.start()

func _add_score(score: int) -> void:
	self.score += abs(score)
	emit_signal('OnScoreChange')

func _add_lives(lives: int) -> void:
	self.lives += abs(lives)
	emit_signal('OnLivesChange')

func _add_coin(coins: int) -> void:
	self.coins += abs(coins)
	emit_signal('OnCoinCollected')

func _delay() -> void:
	if not get_tree().get_current_scene().get_node('Mario').dead:
		emit_signal('TimeTick')
		time -= 1
		if time == -1:
			_pll()

func _pll() -> void: # Player Lose Life
	if player_dead:
		return
	player_dead = true
	emit_signal('OnPlayerLoseLife')
	var scene = get_tree().get_current_scene()
	scene.get_node('Music Controller').play_music('1-music-die.it')
	scene.get_node('Mario').dead = true
