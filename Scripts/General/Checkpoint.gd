extends Area2D


var active: bool = false
export var id: int = 0

var counter: float = 0

var rng = RandomNumberGenerator.new()

func _ready() -> void:
  if Global.checkpoint_active == id:
    active = true
    $AnimatedSprite.animation = 'active'
    Global.Mario.position = position
    var level = Global.Mario.get_parent()
    if (
      'time_after_checkpoint' in level
      and level.time_after_checkpoint.size() > 0
      and level.time_after_checkpoint[id] > 0
    ):
      yield(get_tree(), 'idle_frame')
      Global.time = Global.Mario.get_parent().time_after_checkpoint[id]

func _process(delta: float) -> void:
  rng.randi_range(0, 1)
  
  if is_instance_valid(self) and Global.is_mario_collide_area('InsideDetector', self) and !active:
    active = true
    $AnimatedSprite.animation = 'active'
    $Sound.play()
    counter = 1
    Global.checkpoint_active = id
    Global.checkpoint_position = position
    
  if counter > 0 and counter < 50:
    counter += 1 * Global.get_delta(delta)
  elif counter >= 50 and counter < 999:
    counter = 999
    var nodes = [get_node('MSound1'), get_node('MSound2'), get_node('MSound3')]
    var mnode = nodes[rng.randi_range(0, 2)] as AudioStreamPlayer2D
    mnode.stream.set_loop(false)
    mnode.play()
    
