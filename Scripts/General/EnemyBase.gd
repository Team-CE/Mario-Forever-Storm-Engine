extends KinematicBody2D
class_name EnemyBase

#AI Types
enum AI_TYPE {
	IDLE,
	WALK,
	FLY,
	FREE
}

var velocity : Vector2
var dir : float = 1

onready var DebugText : Label = Label.new()

signal on_stomp

export var speed : float = 70
export var smart_turn : bool
export var no_gravity : bool
export var can_be_stomped : bool

export(AI_TYPE) var ai : int = AI_TYPE.IDLE

func _ready():
	var feets = preload("res://Objects/Enemies/Core/Feets.tscn").instance()
	if smart_turn:
		feets.connect("on_cliff",self,'_turn')
	
	self.add_child(feets)
	
	if !Global.debug:
		DebugText.queue_free()
	else:
		DebugText.align = Label.ALIGN_CENTER
		DebugText.valign = Label.VALIGN_CENTER
		DebugText.grow_horizontal = Control.GROW_DIRECTION_BOTH
		DebugText.grow_vertical = Control.GROW_DIRECTION_BEGIN
		DebugText.rect_position = Vector2(0,-62)
		add_child(DebugText)

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
	
	if Global.debug:
		Debug()
	
	#Gravity
	if !is_on_floor():
		velocity.y += Global.gravity * Global.get_delta(delta)
	
	velocity = move_and_slide(velocity,Vector2.UP)

#Just standing AI
func IDLE_AI(delta : float) -> void:
	velocity.x = 0

#Walking AI
func WALK_AI(delta : float) -> void:
	velocity.x = speed * dir * Global.get_delta(delta)
	if is_on_wall():
		_turn()

#Flying AI
func FLY_AI(delta : float) -> void:
	velocity.y = sin(position.x)# * Global.get_delta(delta)

#Free move AI
func FREE_AI(delta : float) -> void:
	pass

func _turn() -> void:
	$Sprite.flip_h = dir > 0
	velocity.x = -dir * speed * 2
	dir = -dir

func Debug() -> void:
	DebugText.text = 'Vel:{Vel}\nDir:{Dir}\nSm_T:{Sm_T}'.format({'Vel':velocity, 'Dir':dir,'Sm_T':smart_turn})
