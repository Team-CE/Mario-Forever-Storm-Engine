extends StaticBody2D
class_name QSwitchBlock, "res://GFX/Editor/QBlock.png"
tool

export(bool) var Block: bool
export(bool) var Enabled: bool
export var id: int = 0
export var hsv_shift: int = 0

var blockShape: Shape2D
var collision: CollisionShape2D
var preview: Sprite
var body: AnimatedSprite

var active: bool = true
var triggered: bool = false
var t_counter: float = 0

var initial_position: Vector2

func _ready():
  initial_position = position

  # If alrady loaded
  if get_node_or_null('Body') != null:
    collision = $Collision
    body = $Body
    return
  
  body.material = material

  add_to_group('Solid', true)
  add_to_group('Breakable', true)
  
  # Collision
  blockShape = RectangleShape2D.new()
  blockShape.extents = Vector2(16, 16)
  
  collision = CollisionShape2D.new()
  collision.name = 'Collision'
  collision.shape = blockShape
  collision.position.y -= 16
  collision.visible = false
  
  add_child(collision)
  collision.set_owner(self)
  
  # Animated sprite Sprite
  body = AnimatedSprite.new()
  body.name = 'Body'
  body.offset = Vector2(0, -16)
  body.z_index = 1
  body.frames = preload('res://Prefabs/Blocks/Question Block.tres')
  body.playing = true
  
  add_child(body)
  body.set_owner(self)


func editor() -> void:
  if body:
    if body.animation != 'default' and !Block:
      body.animation = 'default'
    elif body.animation != 'empty' and Block:
      body.animation = 'empty'
    
    if body.animation == 'empty':
      body.frame = 1 if !Enabled else 0
    
    body.material.set_shader_param('Shift_Hue', hsv_shift / 100.0)

func _process(delta) -> void:
  if active:
    _process_active(delta)

  if triggered:
    _process_trigger(delta)


func _physics_process(_delta) -> void:
  editor()

func _process_active(_delta) -> void:
  if Engine.editor_hint:
    return
  
  if Block:
    $Collision.disabled = !Enabled

  $Body.visible = visible

func hit(_a = false, _b = false) -> void:
  if not active or Block: return
  active = false
  triggered = true
  visible = true
  $Body.visible = visible
  $Collision.one_way_collision = false
  Global.play_base_sound('MISC_Switch')
  
  toggle_switches()

func toggle_switches() -> void:
  var nodes = get_parent().get_children()
  
  for node in nodes:
    if 'Enabled' in node and 'Block' in node and node.Block and 'id' in node and node.id == id:
      node.Enabled = !node.Enabled

func _process_trigger(delta) -> void:
  t_counter += (1 if t_counter < 200 else 0) * Global.get_delta(delta)
  
  if t_counter < 12:
    position += Vector2(0, (-1 if t_counter < 6 else 1) * Global.get_delta(delta)).rotated(rotation)
  
  if t_counter >= 12:
    position = initial_position
    triggered = false
    t_counter = 0
    active = true
      

func getInfo() -> String:
  return '{b}\n{p}: {t}\n{c}'.format({'b':body,'p':preview,'t':null,'c':collision}).to_lower()
