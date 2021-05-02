extends KinematicBody2D
class_name EnemyBase

#AI Types
enum AI_TYPE {
	IDLE,
	WALK,
	FLY,
	FREE
}

var vis : VisibilityEnabler2D = VisibilityEnabler2D.new()
var onScreen : bool

var velocity : Vector2
var dir : float = 1

signal on_stomp

export var speed : float = 70
export var smart_turn : bool
export var no_gravity : bool
export var can_be_stomped : bool

export var sin_height : float = 20
export var sin_speed : float = 150

export(AI_TYPE) var ai : int = AI_TYPE.IDLE

func _ready():
	vis.process_parent = true
	vis.physics_process_parent = true
	vis.connect("screen_entered",self,"_on_screen_entered")
	vis.connect("screen_exited",self,"_on_screen_exited")
	
	add_child(vis)
	
	
	var feets = preload("res://Objects/Enemies/Core/Feets.tscn").instance()
	if smart_turn and ai == AI_TYPE.WALK:
		feets.connect("on_cliff",self,'_turn')
	
	self.add_child(feets)

#_AI() function redirect to other AI functions
func _AI(delta : float) -> void:
	match ai:
		AI_TYPE.IDLE:
			IDLE_AI(delta)
		AI_TYPE.WALK:
			WALK_AI(delta)
		AI_TYPE.FLY:
			FLY_AI(delta)
		AI_TYPE.FREE:
			FREE_AI(delta)

func _process(delta : float) -> void:
	_AI(delta)
	
	#Gravity
	if !is_on_floor() && ai != AI_TYPE.FLY:
		velocity.y += Global.gravity
	
	velocity = move_and_slide(velocity,Vector2.UP)

#Just standing AI
func IDLE_AI(delta : float) -> void:
	velocity.x = 0

#Walking AI
func WALK_AI(delta : float) -> void:
	velocity.x = speed * dir
	if is_on_wall():
		_turn()

#Flying AI
func FLY_AI(delta : float) -> void:
	velocity.x = speed * dir
	velocity.y = (sin(position.x/sin_height)*sin_speed)
	if is_on_wall():
		_turn()

#Free move AI
func FREE_AI(delta : float) -> void:
	pass

func _turn() -> void:
	$Sprite.flip_h = dir > 0
	velocity.x = -dir * speed * 2
	dir = -dir

func getInfo() -> String:
	return "{self}\nvel:{velocity}\nspeed:{speed}\nSmart:{smart_turn}\nCan stmpd:{can_be_stomped}\nDir:{dir}\nOn screen:{onScreen}".format({"self":name,"velocity":velocity,"speed":speed,"smart_turn":smart_turn,"can_be_stomped":can_be_stomped,"dir":dir,"onScreen":onScreen}).to_lower()

func _on_screen_entered():
	onScreen = true

func _on_screen_exited():
	onScreen = false
