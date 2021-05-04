extends KinematicBody2D
class_name EnemyBase

# AI Types
enum AI_TYPE {
	IDLE,
	WALK,
	FLY,
	FREE
}

enum DEAD_TYPE {
	BASIC
}

var vis: VisibilityEnabler2D = VisibilityEnabler2D.new()
var onScreen: bool

var velocity: Vector2

signal on_stomp

export var dir: float = -1

export var speed: float = 70
export var smart_turn: bool
export var no_gravity: bool
export var is_stompable: bool

export var sin_height: float = 20
export var sin_speed: float = 150
export var score: int = 100

export var alive: bool = true

export(AI_TYPE) var ai: int = AI_TYPE.IDLE
export(DEAD_TYPE) var dead: int = DEAD_TYPE.BASIC

var dead_complete: bool = false

func _ready() -> void:
	vis.process_parent = true
	vis.physics_process_parent = true
	vis.connect("screen_entered",self,"_on_screen_entered")
	vis.connect("screen_exited",self,"_on_screen_exited")
	
	add_child(vis)
	
	var feets = preload("res://Objects/Enemies/Core/Feets.tscn").instance()
	if smart_turn and ai == AI_TYPE.WALK:
		feets.connect("on_cliff",self,'_turn')
	
	self.add_child(feets)
	
	self.add_to_group('Enemy')

# _AI() function redirect to other AI functions
func _AI(delta: float) -> void:
	match ai:
		AI_TYPE.IDLE:
			IDLE_AI(delta)
		AI_TYPE.WALK:
			WALK_AI(delta)
		AI_TYPE.FLY:
			FLY_AI(delta)
		AI_TYPE.FREE:
			FREE_AI(delta)

func _process(delta) -> void:
	# Gravity
	if !is_on_floor() && ai != AI_TYPE.FLY:
		velocity.y += Global.gravity

	velocity = move_and_slide(velocity, Vector2.UP)

	if alive:
		_process_alive(delta)
	else:
		if not dead_complete:
			_process_dead(delta)
		dead_complete = true

func _process_alive(delta: float) -> void:
	_AI(delta)
	
	# Stomping
	var mario = get_parent().get_node('Mario')
	var mario_bd = mario.get_node('BottomDetector')
	var mario_pd = mario.get_node('InsideDetector')
	var pd_overlaps = mario_pd.get_overlapping_bodies()
	var bd_overlaps = mario_bd.get_overlapping_bodies()

	if bd_overlaps and bd_overlaps[0] == self and not (pd_overlaps and pd_overlaps[0] == self) and is_stompable:
		if Input.is_action_pressed('mario_jump'):
			mario.y_speed = -13
		else:
			mario.y_speed = -8
		mario.get_node('BaseSounds').get_node('ENEMY_Stomp').play()
		alive = false
		
		var score_text = ScoreText.new(score,position)
		get_parent().add_child(score_text)
	
	if pd_overlaps and pd_overlaps[0] == self:
		Global._pll()

func _process_dead(delta: float) -> void:
	$Sprite.set_animation('Dead')
	match dead:
		DEAD_TYPE.BASIC:
			velocity.x = 0
			collision_layer = 2
			collision_mask = 2
			yield(get_tree().create_timer(2.0), 'timeout')
			queue_free()

# Just standing AI
func IDLE_AI(delta: float) -> void:
	velocity.x = 0

# Walking AI
func WALK_AI(delta: float) -> void:
	velocity.x = speed * dir
	if is_on_wall():
		_turn()

# Flying AI
func FLY_AI(delta: float) -> void:
	velocity.x = speed * dir
	velocity.y = (sin(position.x / sin_height) * sin_speed)
	if is_on_wall():
		_turn()

# Free move AI
func FREE_AI(delta: float) -> void:
	pass

func _turn() -> void:
	$Sprite.flip_h = dir > 0
	velocity.x = -dir * speed * 2
	dir = -dir

func getInfo() -> String:
	return "{self}\nvel:{velocity}\nspeed:{speed}\nSmart:{smart_turn}\nCan stmpd:{is_stompable}\nDir:{dir}\nOn screen:{onScreen}".format({"self":name,"velocity":velocity,"speed":speed,"smart_turn":smart_turn,"is_stompable":is_stompable,"dir":dir,"onScreen":onScreen}).to_lower()

func _on_screen_entered() -> void:
	onScreen = true

func _on_screen_exited() -> void:
	onScreen = false

