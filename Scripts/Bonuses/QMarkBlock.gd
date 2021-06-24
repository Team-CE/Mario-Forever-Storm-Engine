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
  COIN_BRICK
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
  body.z_index = 20
  body.frames = preload('res://Prefabs/Blocks/Question Block.tres')
  body.playing = true
  
  add_child(body)
  body.set_owner(self)
  
  # Preview Sprite
  preview = Sprite.new()
  preview.name= 'Preview'
  preview.scale = Vector2(0.5, 0.5)
  preview.modulate.a = 0.8
  preview.position.x += 8
  preview.position.y -= 8
  preview.z_index = 21
  preview.texture = set_preview()
  
  add_child(preview)
  preview.set_owner(self)
  
  if Empty:
    body.animation = 'empty'
  if not Visible == VISIBILITY_TYPE.VISIBLE and !Engine.editor_hint:
    visible = false


func editor() -> void:
  if body.animation != 'empty' and Empty and qtype == BLOCK_TYPE.COMMON:
    body.animation = 'empty'
  elif body.animation != 'default' and not Empty and qtype == BLOCK_TYPE.COMMON:
    body.animation = 'default'
  if body.animation != 'brick' and qtype != BLOCK_TYPE.COMMON:
    body.animation = 'brick'


  if (Result != null || PrevResult != null) && Result != PrevResult:
    preview.texture = set_preview()
  
  body.modulate.a = 0.5 if Visible != VISIBILITY_TYPE.VISIBLE else 1.0

  if Frames != null && Frames != PrevFrames:
    body.frames = Frames
  
    print(Frames.resource_path)
    PrevFrames = Frames


func set_preview() -> StreamTexture:
  var result_inst = Result.instance()
  var sprite = result_inst.get_node_or_null('Sprite') if is_instance_valid(Result) else null
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
  
  if qtype != BLOCK_TYPE.COMMON and not Empty:
    body.animation = 'brick'
  
  if Empty:
    $Body.set_animation('empty')

  if coin_counter >= 1 and coin_counter <= 7:
    coin_counter += 0.02 * Global.get_delta(delta)


func _physics_process(_delta) -> void:
  preview.visible = Engine.editor_hint || Global.debug

  if Engine.editor_hint:
    editor()
    return

func _process_active(delta) -> void:
  if Engine.editor_hint:
    return
  var mario = Global.Mario
  var mario_td = Global.Mario.get_node('TopDetector')
  var td_overlaps = mario_td.get_overlapping_bodies()

  if td_overlaps and td_overlaps.has(self) and mario.y_speed <= 3 and not mario.standing:
    active = false
    if qtype == BLOCK_TYPE.COMMON:
      $Body.set_animation('empty')
    triggered = true
    visible = true

    if qtype == BLOCK_TYPE.COMMON:
      var powerup = Result.instance()
      powerup.position = position
      powerup.appearing = true
      get_parent().add_child(powerup)
      if powerup.appearing and powerup is KinematicBody2D:
        Global.play_base_sound('MAIN_PowerupGrow')
    elif qtype == BLOCK_TYPE.BRICK:
      if Global.state == 0:
        Global.play_base_sound('MAIN_Bump')
      else:
        brick_break()
    elif qtype == BLOCK_TYPE.COIN_BRICK:
      if coin_counter == 0:
        coin_counter = 1
      if coin_counter <= 100:
        Global.play_base_sound('MAIN_Coin')
        Global.add_coins(1)

        var coin_effect = CoinEffect.new(position + Vector2(0, -32))
        get_parent().add_child(coin_effect)

        if coin_counter > 6:
          Empty = true
          $Body.set_animation('Empty')
          qtype = BLOCK_TYPE.COMMON
          coin_counter = 100

func brick_break():
  Global.play_base_sound('MAIN_BrickBreak')
  var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
  for i in range(4):
    var debris_effect = BrickEffect.new(position + Vector2(0, -16), speeds[i])
    get_parent().add_child(debris_effect)
  Global.add_score(50)
  queue_free()

func _process_trigger(delta) -> void:
  t_counter += (1 if t_counter < 200 else 0) * Global.get_delta(delta)
  
  if t_counter < 12:
    position.y += (-1 if t_counter < 6 else 1) * Global.get_delta(delta)
  
  if t_counter >= 12:
    position = initial_position
    if qtype != BLOCK_TYPE.COMMON:
      t_counter = 0
      triggered = false
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
