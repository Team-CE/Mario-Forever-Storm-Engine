extends CanvasLayer

var isPaused: bool = true
var why: bool = false

onready var env = get_parent().get_node('WorldEnvironment').environment
onready var cm = CanvasModulate.new()

export var darkness: float = 0.35
export var speed: float = 0.15

var cm2

func _ready():
  cm.z_index = 99
  get_parent().add_child(cm)
  if get_parent().get_node_or_null('ParallaxBackground'):
    cm2 = CanvasModulate.new()
    get_parent().get_node('ParallaxBackground').add_child(cm2)

  if Global.HUD:
    for child in Global.HUD.get_children():
      if not child is AudioStreamPlayer:
        child.hide()

func _process(delta):
  if isPaused:
    if cm.color.v > 0.355:
      cm.color.v += (darkness - cm.color.v) * speed * Global.get_delta(delta)
      if cm2:
        cm2.color.v += (darkness - cm2.color.v) * speed * Global.get_delta(delta)
      env.dof_blur_near_amount += (darkness - env.dof_blur_near_amount) * darkness * Global.get_delta(delta)
      
      # Hiding canvas layers
      for node in get_parent().get_children():
        if node is ParallaxBackground:
          for n in node.get_children():
            if n is Sprite:
              continue
            var block_go = false
            for nc in n.get_children():
              if nc is Sprite and nc.texture is GradientTexture:
                block_go = true
            if block_go:
              continue
            n.modulate.a += (0 - n.modulate.a) * speed * Global.get_delta(delta)
          
      
    else:
      if !why:
        for node in get_children():
          if node is Node:
            for spr in get_children():
              if spr is AnimatedSprite or spr is Sprite:
                spr.modulate.a = 1
        cm.color.v = darkness
        # Hiding canvas layers
        for node in get_parent().get_children():
          if node is ParallaxBackground:
            for n in node.get_children():
              if n is Sprite:
                continue
              var block_go = false
              for nc in n.get_children():
                if nc is Sprite and nc.texture is GradientTexture:
                  block_go = true
              if block_go:
                continue
              n.modulate.a = 0
        why = true

  else:
    cm.color.v += (1 - cm.color.v) * speed * Global.get_delta(delta)
    if cm2:
      cm2.color.v += (1 - cm2.color.v) * speed * Global.get_delta(delta)
    # Showing canvas layers
    for node in get_parent().get_children():
      if node is ParallaxBackground:
        for n in node.get_children():
          if n is Sprite:
            continue
          var block_go = false
          for nc in n.get_children():
            if nc is Sprite and nc.texture is GradientTexture:
              block_go = true
          if block_go:
            continue
          n.modulate.a += (1 - n.modulate.a) * speed * Global.get_delta(delta)
    env.dof_blur_near_amount += (0 - env.dof_blur_near_amount) * speed * Global.get_delta(delta)

func resume() -> void:
  if Global.HUD:
    for child in Global.HUD.get_children():
      if (not child is AudioStreamPlayer) and (not 'DebugOrphaneNodes' in child.name):
        child.show()
        
    Global.HUD.get_node('DebugFlySprite').visible = Global.debug_fly
    Global.HUD.get_node('DebugInvisibleSprite').visible = Global.debug_inv
    Global.HUD.get_node('GameoverSprite').visible = Global.Mario.dead_gameover
    Global.HUD.get_node('DebugOrphaneNodes').hide()
  isPaused = false
  
  yield(get_tree().create_timer( darkness ), 'timeout')
  
  cm.modulate = Color.white
  if cm2: cm2.modulate = Color.white
  
  env.dof_blur_near_enabled = false
  env.dof_blur_near_amount = 0
  
  get_parent().popup = null
  queue_free()
