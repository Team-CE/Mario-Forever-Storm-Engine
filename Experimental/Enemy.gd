extends AliveBody
class_name Enemy, "res://GFX/Editor/Enemy.png"

export var shell_speed: float = 250
export(HIT_TYPE) var on_stomp: bool = HIT_TYPE.STOMP


func _ready():
  ._ready() #Execute part in Class Alive Body
  #Code goes here

func _process_alive(delta) -> void:
  pass

func _process_dead(delta) -> void:
  pass

func _on_death(killer: Node2D,death_type: int) -> void: #Call function _kill you need with param "self" <ENEMYNAME>._kill(self)
  match death_type:
    DEATH_TYPE.BASIC:
      #TODO: death types @reflexguru
      pass
    DEATH_TYPE.FALL:
      pass
    DEATH_TYPE.DISAPPEAR:
      pass
