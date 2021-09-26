extends Node
class_name Brain

func _setup(b) -> void:
  owner = b

func _ai_process(delta:float) -> void:
  if owner == null:
    return
