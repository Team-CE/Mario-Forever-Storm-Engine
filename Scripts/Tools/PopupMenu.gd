extends CanvasLayer

var isPaused: bool = true
var why: bool = false
var options: bool = false

onready var env = $Sprite.material
onready var bus_effect: Array = []
onready var composited_vol: float = 0

export var darkness: float = 0.35
export var speed: float = 0.15

func _ready():
  if !Global.effects or Global.quality == 0:
    env = null
  var bus_count = AudioServer.get_bus_effect_count(AudioServer.get_bus_index('Sounds'))
  for i in bus_count:
    bus_effect.append(AudioServer.is_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), i))
    AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), i, false)
  composited_vol = AudioServer.get_bus_volume_db(AudioServer.get_bus_index('CompositedSounds'))
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index('CompositedSounds'), 0)

func _process(delta):
  if isPaused:
    if $Sprite.modulate.v > 0.355:
      $Sprite.modulate.v += (darkness - $Sprite.modulate.v) * speed * Global.get_delta(delta)
      if env: env.set_shader_param('amount', env.get_shader_param('amount') + (darkness - env.get_shader_param('amount')) * darkness * Global.get_delta(delta))
      
    else:
      if !why:
        for node in get_children():
          if node.get_class() == 'Node2D':
            node.modulate.a = 1
        $Sprite.modulate.v = darkness
        why = true

  else:
    $Sprite.modulate.v += (1 - $Sprite.modulate.v) * speed * Global.get_delta(delta)
    if env: env.set_shader_param('amount', env.get_shader_param('amount') + (0 - env.get_shader_param('amount')) * speed * Global.get_delta(delta))

func _input(ev):
  if isPaused and ev.is_action_pressed('ui_fullscreen'):
    OS.window_fullscreen = !OS.window_fullscreen

func resume() -> void:
  isPaused = false
  Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
  
  for i in bus_effect.size():
    AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), i, bus_effect[i])
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index('CompositedSounds'), composited_vol)

# warning-ignore:return_value_discarded
  get_tree().create_timer( darkness, false).connect('timeout', self, '_next')

func _next():
  $Sprite.modulate = Color.white
  
  if Global.current_scene.popup: Global.current_scene.popup = null
  queue_free()
