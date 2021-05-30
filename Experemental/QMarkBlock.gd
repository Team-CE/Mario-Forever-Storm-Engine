extends StaticBody2D
class_name QBlock
tool

enum VISIBILITY_TYPE {
  VISIBLE,
  INVIS_ONCE,
  INVIS_ALWAYS
}

export(VISIBILITY_TYPE) var Visible: int

var PrevResult: Resource
export(PackedScene) var Result: PackedScene

var PrevFrames: SpriteFrames
export(SpriteFrames) var Frames: SpriteFrames

export(int,1,100) var Count: int = 1

export(bool) var Empty: bool

export(bool) var Breakable: bool

var blockShape: Shape2D
var collision: CollisionShape2D
var preview: Sprite
var body: AnimatedSprite
  
func _ready() -> void:
  #If alrady loaded
  if get_node_or_null('Body') != null:
    collision = $Collision
    body = $Body
    preview = $Preview
    return

    
  add_to_group('Solid', true)
  add_to_group('Breakable', true)
    
  PrevResult = Result
  PrevFrames = Frames
  
  #Collision
  blockShape = RectangleShape2D.new()
  blockShape.extents = Vector2(16,16)
  
  collision = CollisionShape2D.new()
  collision.name = 'Collision'
  collision.shape = blockShape
  collision.position.y -= 16
  collision.visible = false
  
  collision.set_owner(self)
  add_child(collision)
  
  #Animated sprite Sprite
  body = AnimatedSprite.new()
  body.name = 'Body'
  body.offset = Vector2(0,-16)
  body.z_index = 20
  body.frames = preload('res://Prefabs/Blocks/Question Block.tres')
  body.playing = true
  
  body.set_owner(self)
  add_child(body)
  
  #Preview Sprite
  preview = Sprite.new()
  preview.name= 'Preview'
  preview.scale = Vector2(0.5,0.5)
  preview.modulate.a = 0.8
  preview.position.x += 8
  preview.position.y -= 8
  preview.z_index = 21
  preview.texture = set_preview()
  
  preview.set_owner(self)
  add_child(preview)
  
  if Empty:
    body.animation = 'empty'


func editor() -> void:
  if body.animation != 'empty' && Empty:
    body.animation = 'empty'
  elif body.animation != 'default' && !Empty:
    body.animation = 'default'


  if Result != null && Result != PrevResult:
    preview.texture = set_preview()
  
  body.modulate.a = 0.5 if Visible != VISIBILITY_TYPE.VISIBLE else 1.0

  if Frames != null && Frames != PrevFrames:
    body.frames = Frames
  
    print(Frames.resource_path)
    PrevFrames = Frames


func set_preview() -> StreamTexture:
  var sprite = Result.instance().get_node_or_null('Sprite') if is_instance_valid(Result) else null
  var res
  
  if preview == null || !is_instance_valid(sprite):
    return GlobalEditor.NULLTEXTURE as StreamTexture  
    
  preview.scale = sprite.scale * Vector2(0.5,0.5)
  print(sprite)
  
  res = sprite.frames.get_frame(sprite.animation,0) if sprite is AnimatedSprite else sprite.texture if sprite is Sprite else GlobalEditor.NULLTEXTURE as StreamTexture

  PrevResult = Result
  print(res)
  return res


func _physics_process(_delta):
  preview.visible = Engine.editor_hint || Global.debug

  if Engine.editor_hint:
    editor()
    return


func _on_hit():
  if Breakable:
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
