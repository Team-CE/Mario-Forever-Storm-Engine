extends Node2D


var counter: float = 0

func _ready():
  if Global.musicBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(Global.musicBar / 5))
  visible = true

func _process(delta):
  if get_parent().isPaused:
    modulate.a += (1 - modulate.a) * 0.05 * Global.get_delta(delta)
    counter += 0.15 * Global.get_delta(delta)
    var sinalpha = sin(counter) * 0.3 + 0.7
    $sel0.modulate.a = sinalpha
  else:
    modulate.a += (0 - modulate.a) * 0.15 * Global.get_delta(delta)
  
  if Input.is_action_just_pressed('ui_accept') and counter > 5:
    get_parent().resume()
    get_parent().get_parent().get_tree().paused = false
    get_tree().get_current_scene().freeRestartPrompt()
