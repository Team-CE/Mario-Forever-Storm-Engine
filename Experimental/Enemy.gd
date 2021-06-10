extends AliveBody
class_name Enemy, "res://GFX/Editor/Enemy.png"

export(HIT_TYPE) var on_stomp: bool = HIT_TYPE.STOMP

func _ready():
  ._ready() #Execute part in Class Alive Body
  #Code goes here

func _process_alive(delta) -> void:
  pass

func _process_dead(delta) -> void:
  pass
