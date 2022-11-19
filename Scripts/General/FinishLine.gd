extends Node2D

export var set_level_id: int = 0
export var map_scene: String = ''

var win_music = preload('res://Music/1-music-complete-level.ogg')

var initial_position: float
var counter: float = 0

var crossed: bool = false
var warp_finish: bool = false

var bar_enabled: bool = false
var bar_accel: float = -6

var final_score: int
onready var wait_counter: float = 30

func _init():
	win_music.loop = false

func _ready() -> void:
	initial_position = $CrossingBar.position.y
	win_music.loop = false
	
	if 'finish_node' in Global.current_scene:
		Global.current_scene.finish_node = self

func _physics_process(delta) -> void:
	if not crossed:
		counter += 1 * Global.get_delta(delta)
		if counter < 75:
			$CrossingBar.position.y += 3 * Global.get_delta(delta)
		elif counter < 150:
			$CrossingBar.position.y -= 3 * Global.get_delta(delta)
		else:
			counter = 0
			$CrossingBar.position.y = initial_position
		
		if Global.Mario.get_node('InsideDetector').get_overlapping_areas().has($CrossingBar) or (Global.Mario.position.x >= position.x + 24 and Global.Mario.is_on_floor() and Global.Mario.position.y < position.y + 128):
			if Global.Mario.get_node('InsideDetector').get_overlapping_areas().has($CrossingBar):
				bar_enabled = true
				$CrossingBar/Sprite.set_animation('crossed')
				var given_score: int
				var calculated_y: float = $CrossingBar.position.y - initial_position
				if calculated_y < 30:
					given_score = 10000
				elif calculated_y < 60:
					given_score = 5000
				elif calculated_y < 100:
					given_score = 2000
				elif calculated_y < 150:
					given_score = 1000
				elif calculated_y < 200:
					given_score = 500
				else:
					given_score = 200
				var score_text = ScoreText.new(given_score, Global.Mario.position)
				get_parent().add_child(score_text)
			else:
				var score_text = ScoreText.new(100, Global.Mario.position)
				get_parent().add_child(score_text)
			act()
	else:
		finish_process(delta)
		if not warp_finish:
			Global.Mario.velocity.x = 150

			if bar_enabled:
				$CrossingBar.position.x -= 3 * Global.get_delta(delta)
				$CrossingBar.position.y += bar_accel * Global.get_delta(delta)
				bar_accel += 0.2 * Global.get_delta(delta)
				$CrossingBar.rotation_degrees += 17 * Global.get_delta(delta)

func finish_process(delta):
	counter += 1 * Global.get_delta(delta)
	if counter > 400:
		if Global.time > 0:
# warning-ignore:narrowing_conversion
			Global.time -= round(9 * Global.get_delta(delta))
# warning-ignore:narrowing_conversion
			Global.add_score(round(90 * Global.get_delta(delta)))
			Global.emit_signal('TimeTick')
			if not Global.HUD.get_node('ScoreSound').playing:
				Global.HUD.get_node('ScoreSound').play()
		elif Global.time <= 0:
			Global.time = 0
			Global.emit_signal('TimeTick')
			Global.score = final_score
			Global.HUD.get_node('Score').text = str(final_score)
			Global.emit_signal('OnScoreChange')
			wait_counter -= 1 * Global.get_delta(delta)
			Global.levelID = set_level_id
			if wait_counter < 0:
				Global.reset_audio_effects()
				Global.Mario.visible = true
				Global.deaths = 0
				Global.level_ended = false
				if Global.collectible_saved or Global.collectible_obtained:
					Global.collectibles += 1
					Global.collectible_saved = true
					Global.collectible_obtained = false
				Global.goto_scene(map_scene)
	
func act(warp_finish_enabled: bool = false) -> void:
	Global.level_ended = true
	crossed = true
	MusicPlayer.get_node('Main').stream = win_music
	MusicPlayer.get_node('Main').play()
	MusicPlayer.stop_on_pause()
	MusicPlayer.get_node('Star').stop()
	Global.checkpoint_active = -1
	Global.checkpoint_position = Vector2.ZERO
	Global.Mario.controls_enabled = false
	Global.Mario.invulnerable = true
	counter = 0
	warp_finish = warp_finish_enabled
	final_score = Global.score + (Global.time * 10)
	for i in get_tree().get_nodes_in_group('Projectile'):
		if i.has_method('_on_level_complete'):
			var score = i._on_level_complete()
			if score and typeof(score) == TYPE_INT:
# warning-ignore:narrowing_conversion
				final_score += abs(score)
				Global.add_score(score)
	
	var scrtext: int = 0
	if Global.collectibles + int(Global.collectible_obtained) in Global.collectibles_scrolltext:
		scrtext = Global.collectibles + int(Global.collectible_obtained)
	if Global.collectible_obtained and scrtext:
		var scroll = preload('res://Objects/Tools/ScrollText.tscn').instance()
		Global.HUD.add_child(scroll)
		scroll.text = Global.collectibles_scrolltext[scrtext]
	
	Global.reset_audio_effects()
