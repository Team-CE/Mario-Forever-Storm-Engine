extends Node2D

signal on_cliff

func _ready() -> void:
  $Feet_L.visible = false

func _on_body_exit(body: Node2D, left: bool) -> void:
  if left:
    $Feet_L.visible = false#visual only
    $Feet_R.visible = true
  else:
    $Feet_L.visible = true
    $Feet_R.visible = false
  
  if !body.is_in_group('Solid'):
    return
  emit_signal('on_cliff')
