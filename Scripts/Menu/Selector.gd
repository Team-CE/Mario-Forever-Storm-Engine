extends AnimatedSprite

var time

func _ready() -> void:
  time = get_tree().create_timer(0)
  connect('animation_finished', self, 'animends')

func _process(delta):
  # Random Blinking
  if !playing && time.time_left <= 0.0:
    randomize()                          # For full random
    var rand = randi() % 5 + 2           # Get a Random number
    time = get_tree().create_timer(rand) # Create a new SceneTimer
    yield(time, 'timeout')               # Delay
    playing = true                       # Set anim play
    
func animends():
  playing = false
