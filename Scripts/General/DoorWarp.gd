tool
extends Area2D

enum TYPES {
  IN,
  OUT
}

export var id: int = 0
export(TYPES) var type: int = TYPES.IN

var counter: float = 0
var active: bool = false
var switch: bool = false

var door_warp: bool = true

var out_node
var disabled: bool = false

func _ready() -> void:
  if !Engine.editor_hint:
    $Label.queue_free()
    
  var nodes = get_tree().get_nodes_in_group('DoorWarp')
    
  for node in nodes:
    if node.id == id and node.type == TYPES.OUT and 'door_warp' in node:
      out_node = node
      
  disabled = not out_node
  
  if disabled:
    printerr('[CE ERROR] No out door-warp assigned for id ' + str(id) + ', it will not be functional. Create an out door-warp or set an additional option.')

func _process(delta: float) -> void:
  if Engine.editor_hint:
    $Label.text = str(id) + '\n' + ('IN' if type == TYPES.IN else 'OUT')
  else:
    if Input.is_action_pressed('mario_up') and Global.is_mario_collide_area('InsideDetector', self):
      active = true
      Global.Mario.position.x = position.x
      Global.Mario.controls_enabled = false
      Global.Mario.animation_enabled = false
      Global.Mario.velocity = Vector2(0, 0)
      Global.Mario.get_node('Sprite').animation = 'Stopped'
    
    if active and counter < 40:
      counter += 1 * Global.get_delta(delta)
      Global.Mario.get_node('Sprite').modulate.a -= 0.03 * Global.get_delta(delta)
      
    if active and counter >= 40:
      if !switch:
        switch = true
        Global.Mario.get_node('Sprite').modulate.a = 0
        Global.Mario.position = out_node.position
      counter += 1 * Global.get_delta(delta)
      Global.Mario.get_node('Sprite').modulate.a += 0.03 * Global.get_delta(delta)
      
    if active and counter >= 80:
      Global.Mario.get_node('Sprite').modulate.a = 1
      Global.Mario.controls_enabled = true
      Global.Mario.animation_enabled = true
      

