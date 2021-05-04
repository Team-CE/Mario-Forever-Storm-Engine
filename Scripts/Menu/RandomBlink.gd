extends AnimatedSprite

var time

func _ready() -> void:
#	var an : AnimationPlayer = get_parent().get_parent().get_node("AnimationPlayer")
#	an.connect("animation_finished",self,"animFinished")
	time = get_tree().create_timer(0)
	connect("animation_finished",self,'animends')
	pass

func _process(delta):
	if !playing && time.time_left <= 0.0:
		randomize()                          #For full random
		var rand = randi()%5+2               #Get a Random number
		time = get_tree().create_timer(rand) #Create a new SceneTimer
		yield(time, "timeout")               #Delay
		playing = true                       #Set anim play

func animends():
	playing = false
