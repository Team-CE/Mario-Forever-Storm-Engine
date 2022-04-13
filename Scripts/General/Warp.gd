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
export var immediate: bool = false
export var additional_options: Dictionary = { 'set_scene_path': '' }

var in_icon: StreamTexture = preload('res://GFX/Editor/WarpIcon.png')
var out_icon: StreamTexture = preload('res://GFX/Editor/WarpOutIcon.png')

var disabled: bool = false

var generic_warp: bool = true

var active: bool = false
var counter: float = 0

var state_switched: bool = false

var calc_pos: Vector2

var warp_dir: Vector2 = Vector2.ZERO

var out_node


func _ready() -> void:
  var nodes = get_tree().get_nodes_in_group('Warp')

  for node in nodes:
    if node.id == id and node.type == TYPES.OUT and 'generic_warp' in node:
      out_node = node
      
  disabled = not out_node and (not 'set_scene_path' in additional_options or additional_options['set_scene_path'] == '')
  
  if disabled:
    printerr('[CE ERROR] No out warp assigned for id ' + str(id) + ', it will not be functional. Create an out warp or set an additional option.')
    
  if not Engine.editor_hint:
    $Sprite.visible = false
  
  if not Engine.editor_hint and immediate and Global.checkpoint_active == 0:
    active = true
    out_node = self
    counter = 61
    if Global.state > 0:
      Global.Mario.animate_sprite('Crouching')

func _process(delta) -> void:
  if Engine.editor_hint:
    $Sprite.texture = in_icon if type == TYPES.IN else out_icon
    
    $Sprite.modulate = Color.from_hsv((id / 30.0) - floor(id / 30.0), 1.0, 1.0)
    $Sprite.flip_v = false if direction == DIRS.DOWN or direction == DIRS.RIGHT else true
    $Sprite.rotation_degrees = -90 if direction == DIRS.RIGHT or direction == DIRS.LEFT else 0
  else:
    if disabled: return
    #Вход в варп
    if Global.Mario.get_node('InsideDetector').get_overlapping_areas().has(self) and not active and type == TYPES.IN:
      if direction == DIRS.DOWN and Input.is_action_pressed('mario_crouch'):
        calc_pos = Vector2(position.x, position.y - 16)
        active = true
        Global.invulnerable = true
        Global.play_base_sound('MAIN_Pipe')
        warp_dir.y = 1
        Global.Mario.animate_sprite('Crouching' if Global.state > 0 else 'Stopped')
      elif direction == DIRS.UP and Input.is_action_pressed('mario_up'):
        calc_pos = Vector2(position.x, position.y + 16 + (30 if Global.state != 0 else 0))
        active = true
        Global.invulnerable = true
        Global.play_base_sound('MAIN_Pipe')
        warp_dir.y = -1
      elif direction == DIRS.RIGHT and Input.is_action_pressed('mario_right'):
        calc_pos = Vector2(position.x - 16, position.y + 16)
        active = true
        Global.invulnerable = true
        Global.play_base_sound('MAIN_Pipe')
        Global.Mario.animate_sprite('Walking')
        Global.Mario.get_node("Sprite").speed_scale = 5
        warp_dir.x = 1
      elif direction == DIRS.LEFT and Input.is_action_pressed('mario_left'):
        calc_pos = Vector2(position.x + 16, position.y + 16)
        active = true
        Global.invulnerable = true
        Global.play_base_sound('MAIN_Pipe')
        Global.Mario.animate_sprite('Walking')
        Global.Mario.get_node("Sprite").speed_scale = 5
        warp_dir.x = -1
    
    if active:
      Global.Mario.controls_enabled = false
      Global.Mario.animation_enabled = false
      Global.Mario.position = calc_pos
      Global.Mario.velocity = Vector2(0, 0)
      calc_pos += warp_dir * Global.get_vector_delta(delta)
      counter += 1 * Global.get_delta(delta)

      Global.Mario.get_node('Sprite').z_index = -10

      if counter > 60 and not state_switched: #Выход из варпа
        if out_node:
          state_switched = true
          Global.play_base_sound('MAIN_Pipe')

          if out_node.direction == DIRS.DOWN:
            Global.Mario.crouch = false
            calc_pos = Vector2(out_node.position.x, out_node.position.y - 40 + (24 if Global.state != 0 else 0))
            warp_dir.y = 1
            Global.Mario.animate_sprite('Jumping')
          elif out_node.direction == DIRS.UP:
            Global.Mario.crouch = true
            calc_pos = Vector2(out_node.position.x, out_node.position.y + 44)
            warp_dir.y = -1
            Global.Mario.animate_sprite('Crouching' if Global.state > 0 else 'Stopped')
          elif out_node.direction == DIRS.RIGHT:
            Global.Mario.crouch = false
            calc_pos = Vector2(out_node.position.x - 44, out_node.position.y + 15.9)
            warp_dir.x = 1
            Global.Mario.animate_sprite('Walking')
            Global.Mario.get_node("Sprite").speed_scale = 5
          elif out_node.direction == DIRS.LEFT:
            Global.Mario.crouch = false
            calc_pos = Vector2(out_node.position.x + 44, out_node.position.y + 15.9)
            warp_dir.x = -1
            Global.Mario.animate_sprite('Walking')
            Global.Mario.get_node("Sprite").speed_scale = 5
        elif 'set_scene_path' in additional_options and additional_options['set_scene_path'] != '':
          get_tree().change_scene(additional_options['set_scene_path'])
          
      
      if counter >= 120 and Global.Mario.get_slide_count() == 0:
        Global.Mario.get_node('Sprite').z_index = 10
        state_switched = false
        counter = 0
        active = false
        Global.Mario.controls_enabled = true
        Global.Mario.animation_enabled = true
        Global.invulnerable = false


