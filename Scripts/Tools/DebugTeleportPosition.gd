extends Position2D

# https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#:~:text=enum-,KeyList,-%3A
export var key_scancode: int

func _input(event) -> void:
  if !Global.debug: return

  if 'scancode' in event and event.scancode == key_scancode and event.pressed:
    Global.Mario.position = position
