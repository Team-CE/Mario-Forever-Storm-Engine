extends StaticBody2D
class_name QBlock, "res://GFX/Editor/QBlock.png"
tool

enum VISIBILITY_TYPE {
  VISIBLE,
  INVIS_ONCE,
  INVIS_ALWAYS
}

enum BLOCK_TYPE {
  COMMON,
  BRICK,
  COIN_BRICK,
  RESET_POWERUP
}

export(VISIBILITY_TYPE) var Visible: int

var PrevResult: Resource
export(PackedScene) var Result: PackedScene

var PrevFrames: SpriteFrames
export(SpriteFrames) var Frames: SpriteFrames

var CoinPreview: StreamTexture = preload('res://GFX/Bonuses/CoinPreview.png')

export(int, 1, 100) var Count: int = 1

export(bool) var Empty: bool

export(BLOCK_TYPE) var qtype: int = BLOCK_TYPE.COMMON

var blockShape: Shape2D
var collision: CollisionShape2D
var preview: Sprite
var body: AnimatedSprite

var active: bool = true
var triggered: bool = false
var t_counter: float = 0
var coin_counter: float = 0

var initial_position: Vector2

# TODO #1 Make nodes visible in editor node tree @reflexguru
func _ready():
  initial_position = position

  # If alrady loaded
  if get_node_or_null('Body') != null:
    collision = $Collision
    body = $Body
    preview = $Preview
    return

  add_to_group('Solid', true)
  add_to_group('Breakable', true)
    
  PrevResult = Result
  PrevFrames = Frames
  
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
  
  # Preview Sprite
  preview = Sprite.new()
  preview.name = 'Preview'
  preview.scale = Vector2(0.5, 0.5)
  preview.modulate.a = 0.8
  preview.position.x += 8
  preview.position.y -= 8
  preview.z_index = 2
  preview.texture = set_preview()
  
  add_child(preview)
  preview.set_owner(self)
  
  if Empty:
    body.animation = 'empty'


func editor() -> void:
  if body:
    if body.animation != 'empty' and Empty and qtype == BLOCK_TYPE.COMMON:
      body.animation = 'empty'
    if !Engine.editor_hint:
      if body.animation != 'empty' and Global.state == 0 and qtype == BLOCK_TYPE.RESET_POWERUP:
        body.animation = 'empty'
    elif body.animation != 'default' and not Empty and qtype == BLOCK_TYPE.COMMON:
      body.animation = 'default'
    if body.animation != 'reset' and qtype == BLOCK_TYPE.RESET_POWERUP:
      body.animation = 'reset'
    if body.animation != 'brick' and qtype != BLOCK_TYPE.COMMON and qtype != BLOCK_TYPE.RESET_POWERUP:
      body.animation = 'brick'


  if (Result != null || PrevResult != null) && Result != PrevResult:
    preview.texture = set_preview()
    
  if body:
    body.modulate.a = 0.5 if Visible != VISIBILITY_TYPE.VISIBLE else 1.0


func set_preview() -> StreamTexture:
  if !is_instance_valid(Result): return (GlobalEditor.NULLTEXTURE as StreamTexture)
  var result_inst = Result.instance()
  if !result_inst or !result_inst.has_method('get_node_or_null'):
    return (GlobalEditor.NULLTEXTURE as StreamTexture)
  var sprite = result_inst.get_node_or_null('AnimatedSprite') if is_instance_valid(Result) else null
  if !sprite:
    sprite = result_inst.get_node_or_null('Sprite') if is_instance_valid(Result) else null
  var res
  
  if preview == null || !is_instance_valid(sprite):
    return (GlobalEditor.NULLTEXTURE as StreamTexture) if qtype != BLOCK_TYPE.COIN_BRICK else CoinPreview as StreamTexture
  
  res = sprite.texture if sprite is Sprite else sprite.frames.get_frame('default' if not 'type' in result_inst else sprite.animation, 0) if sprite is AnimatedSprite else null
  
  preview.scale = Vector2(16,16) / res.get_size()
  PrevResult = Result
  #print(res)
  #print(Result)
  return res

func _process(delta) -> void:
  if active:
    _process_active(delta)

  if triggered:
    _process_trigger(delta)
  
  if coin_counter >= 1 and coin_counter <= 6:
    coin_counter += 0.02 * Global.get_delta(delta)
  
  if body and 'animation' in body:
    if qtype != BLOCK_TYPE.COMMON and qtype != BLOCK_TYPE.RESET_POWERUP and not Empty:
      body.animation = 'brick'
      
    if qtype == BLOCK_TYPE.RESET_POWERUP and not Empty:
      body.animation = 'reset'
  
    if Empty:
      $Body.set_animation('empty')
      $Collision.one_way_collision = false
      visible = true


func _physics_process(_delta) -> void:
  if preview:
    preview.visible = Engine.editor_hint || Global.debug
  
  if 'debug' in Global && Global.debug && (Result != null || PrevResult != null) && Result != PrevResult:
    preview.texture = set_preview()
  
  if Frames != null && Frames != PrevFrames:
    body.frames = Frames
    PrevFrames = Frames

  if Engine.editor_hint:
    editor()
    return

func _process_active(delta) -> void:
  if Engine.editor_hint:
    return
  if Visible != VISIBILITY_TYPE.VISIBLE and !Engine.editor_hint:
    if !Empty and !triggered:
      collision.one_way_collision = true
      visible = false
  
  $Body.visible = visible

func brick_break() -> void:
  Global.play_base_sound('MAIN_BrickBreak')
  var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
  for i in range(4):
    var debris_effect = BrickEffect.new(position + Vector2(0, -16), speeds[i])
    get_parent().add_child(debris_effect)
  Global.add_score(50)
  $Body.visible = false
  yield(get_tree(),"idle_frame")
  queue_free()

func hit(delta, thwomp = false) -> void:
  if not active: return
  active = false
  if qtype == BLOCK_TYPE.COMMON:
    $Body.set_animation('empty')
  triggered = true
  visible = true
  $Body.visible = visible
  $Collision.one_way_collision = false

  if qtype == BLOCK_TYPE.COMMON:
    var powerup = Result.instance() if Result and Result.has_method('instance') else null
    if !powerup or (!('vars' in powerup) and !('appearing' in powerup)):
      Global.play_base_sound('MAIN_Bump')
    else:
      powerup.position = position + Vector2(1, 0).rotated(rotation)
      if 'vars' in powerup:
        powerup.vars['from bonus'] = true
      elif 'appearing' in powerup:
        powerup.appearing = true
      powerup.rotation = rotation
      get_parent().add_child(powerup)
      if 'vars' in powerup and powerup.brain.appearing and powerup is KinematicBody2D:
        Global.play_base_sound('MAIN_PowerupGrow')
      if !('vars' in powerup) and 'appearing' in powerup:
        Global.play_base_sound('MAIN_Coin')
  elif qtype == BLOCK_TYPE.BRICK:
    if Global.state == 0 and !thwomp:
      Global.play_base_sound('MAIN_Bump')
    else:
      brick_break()
  elif qtype == BLOCK_TYPE.COIN_BRICK:
    if coin_counter == 0:
      coin_counter = 1
    if coin_counter <= 100:
      Global.play_base_sound('MAIN_Coin')
      Global.add_coins(1)
  
      var coin_effect = CoinEffect.new(position + Vector2(0, -32).rotated(rotation), rotation)
      get_parent().add_child(coin_effect)
  
      if coin_counter >= 6:
        Empty = true
        $Body.set_animation('empty')
        qtype = BLOCK_TYPE.COMMON
        coin_counter = 100
  elif qtype == BLOCK_TYPE.RESET_POWERUP:
    Global.play_base_sound('MAIN_Pipe')
    Global.state = 0
    Global.Mario.appear_counter = 60

func _process_trigger(delta) -> void:
  t_counter += (1 if t_counter < 200 else 0) * Global.get_delta(delta)
  
  if t_counter < 12:
    position += Vector2(0, (-1 if t_counter < 6 else 1) * Global.get_delta(delta)).rotated(rotation)
  
  if t_counter >= 12:
    position = initial_position
    triggered = false
    if qtype != BLOCK_TYPE.COMMON:
      t_counter = 0
      active = true

func _on_hit():
  if qtype == BLOCK_TYPE.COMMON:
    Global.play_base_sound('MAIN_BrickBreak')
    var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
    for i in range(4):
      var debris_effect = BrickEffect.new(position + Vector2(0, -16), speeds[i])
      get_parent().add_child(debris_effect)
    Global.add_score(50)
    queue_free()
  else:
    body.animation = 'empty'
      

func getInfo() -> String:
  return '{b}\n{p}: {t}\n{c}'.format({'b':body,'p':preview,'t':preview.texture.resource_path,'c':collision}).to_lower()
