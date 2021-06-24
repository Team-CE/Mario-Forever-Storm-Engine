extends Area2D
class_name Warp
tool

enum DIRS {
  DOWN,
  UP,
  RIGHT,
  LEFT
}

enum TYPES {
  IN,
  OUT
}

export var id: int = 0
export(DIRS) var direction: int = DIRS.DOWN
export(TYPES) var type: int = TYPES.IN

var in_icon: StreamTexture = preload('res://GFX/Editor/WarpIcon.png')
var out_icon: StreamTexture = preload('res://GFX/Editor/WarpOutIcon.png')

var active: bool = false
var counter: float = 0

var state_switched: bool = false

var calc_pos: Vector2

var warp_dir: Vector2 = Vector2.ZERO

var out_node


func _ready() -> void:
  var nodes = get_tree().get_nodes_in_group('Warp')

  for node in nodes:
    if node.id == id and node.type == TYPES.OUT:
      out_node = node
  
  if not out_node:
    printerr('[CE ERROR] No out warp assigned for id ' + str(id) + ', it will not be functional.')

func _process(delta) -> void:
  if Engine.editor_hint:
    $Sprite.texture = in_icon if type == TYPES.IN else out_icon
    
    $Sprite.modulate = Color.from_hsv((id / 30.0) - floor(id / 30.0), 1.0, 1.0)
    $Sprite.flip_v = false if direction == DIRS.DOWN or direction == DIRS.RIGHT else true
    $Sprite.rotation_degrees = -90 if direction == DIRS.RIGHT or direction == DIRS.LEFT else 0
  else:
    $Sprite.visible = false

    if not out_node: return

    if Global.Mario.get_node('PrimaryDetector').get_overlapping_areas().has(self) and not active and type == TYPES.IN:
      if direction == DIRS.DOWN and Input.is_action_pressed('mario_crouch'):
        calc_pos = Vector2(position.x, position.y - 16)
        active = true
        Global.play_base_sound('MAIN_Pipe')
        warp_dir.y = 1
        Global.Mario.animate_sprite('Crouching')
      elif direction == DIRS.UP and Input.is_action_pressed('mario_up'):
        calc_pos = Vector2(position.x, position.y + 16 + (30 if Global.state != 0 else 0))
        active = true
        Global.play_base_sound('MAIN_Pipe')
        warp_dir.y = -1
      elif direction == DIRS.RIGHT and Input.is_action_pressed('mario_right'):
        calc_pos = Vector2(position.x - 16, position.y + 16)
        active = true
        Global.play_base_sound('MAIN_Pipe')
        Global.Mario.animate_sprite('Walking')
        Global.Mario.speed_scale_sprite(5)
        warp_dir.x = 1
      elif direction == DIRS.LEFT and Input.is_action_pressed('mario_left'):
        calc_pos = Vector2(position.x + 16, position.y + 16)
        active = true
        Global.play_base_sound('MAIN_Pipe')
        Global.Mario.animate_sprite('Walking')
        Global.Mario.speed_scale_sprite(5)
        warp_dir.x = -1
    
    if active:
      Global.Mario.controls_enabled = false
      Global.Mario.animation_enabled = false
      Global.Mario.position = calc_pos
      calc_pos += warp_dir * Global.get_vector_delta(delta)
      counter += 1 * Global.get_delta(delta)

      Global.Mario.get_node('SmallMario').z_index = -10
      Global.Mario.get_node('BigMario').z_index = -10
      Global.Mario.get_node('FlowerMario').z_index = -10
      Global.Mario.get_node('BeetrootMario').z_index = -10

      if counter > 60 and not state_switched:
        state_switched = true
        Global.play_base_sound('MAIN_Pipe')

        if out_node.direction == DIRS.DOWN:
          calc_pos = Vector2(out_node.position.x, out_node.position.y - 44 - (30 if Global.state != 0 else 0))
          warp_dir.y = 1
          Global.Mario.animate_sprite('Jumping')
        elif out_node.direction == DIRS.UP:
          calc_pos = Vector2(out_node.position.x, out_node.position.y + 44)
          warp_dir.y = -1
          Global.Mario.animate_sprite('Crouching')
        elif out_node.direction == DIRS.RIGHT:
          calc_pos = Vector2(out_node.position.x - 44, out_node.position.y + 16)
          warp_dir.x = 1
          Global.Mario.animate_sprite('Walking')
          Global.Mario.speed_scale_sprite(5)
        elif out_node.direction == DIRS.LEFT:
          calc_pos = Vector2(out_node.position.x + 44, out_node.position.y + 16)
          warp_dir.x = -1
          Global.Mario.animate_sprite('Walking')
          Global.Mario.speed_scale_sprite(5)
      
      if counter > 120:
        Global.Mario.get_node('SmallMario').z_index = 10
        Global.Mario.get_node('BigMario').z_index = 10
        Global.Mario.get_node('FlowerMario').z_index = 10
        Global.Mario.get_node('BeetrootMario').z_index = 10
        state_switched = false
        counter = 0
        active = false
        Global.Mario.controls_enabled = true
        Global.Mario.animation_enabled = true


