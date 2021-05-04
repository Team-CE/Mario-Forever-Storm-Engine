extends Node

var gravity: float = 10

var HUD : CanvasLayer
var Mario : Node2D

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
	get_tree().reload_current_scene()
	add_score(0)

func _physics_process(delta) -> void:
	if timer.time_left <= 1 && time != -1:
		_delay()
		timer.start()

func add_score(score: int) -> void:
	self.score += abs(score)
	HUD.get_node('Score').text = str(self.score)
	emit_signal('OnScoreChange')

func add_lives(lives: int) -> void:
	var scorePos = Mario.position
	scorePos.y -= 32
	var ScoreT = ScoreText.new(1,scorePos)
	Mario.get_parent().add_child(ScoreT)
	self.lives += abs(lives)
	HUD.get_node('LifeSound').play()
	HUD.get_node('Lives').text = str(self.lives)
	emit_signal('OnLivesChange')

func add_coins(coins: int) -> void:
	self.coins += abs(coins)
	if self.coins >= 100:
		add_lives(1)
		self.coins = 0
	HUD.get_node('Coins').text = str(self.coins)
	emit_signal('OnCoinCollected')

func _pll() -> void: # Player Lose Life
	if player_dead:
		return
	player_dead = true
	emit_signal('OnPlayerLoseLife')
	var scene = get_tree().get_current_scene()
	scene.get_node('Music Controller').play_music('1-music-die.it')
	Mario.dead = true

func _delay() -> void:
	if Mario == null:
		return
	if !Mario.dead:
		emit_signal('TimeTick')
		time -= 1
		if time == -1:
			_pll()
