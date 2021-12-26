extends CanvasLayer

var isPaused: bool = true
var why: bool = false

onready var env = get_parent().get_node('WorldEnvironment').environment
onready var cm = CanvasModulate.new()
var cm2

func _ready():
  #cm.set_owner(self)
  cm.z_index = 99
  get_parent().add_child(cm)
  if get_parent().get_node_or_null('ParallaxBackground'):
    cm2 = CanvasModulate.new()
    get_parent().get_node('ParallaxBackground').add_child(cm2)

  if get_parent().get_node_or_null('HUD'):
    for child in Global.HUD.get_children():
      if not child is AudioStreamPlayer:
        child.hide()

func _process(delta):
  if isPaused:
    if cm.color.r > 0.355:
      cm.color.r += (0.35 - cm.color.r) * 0.15 * Global.get_delta(delta)
      cm.color.g += (0.35 - cm.color.g) * 0.15 * Global.get_delta(delta)
      cm.color.b += (0.35 - cm.color.b) * 0.15 * Global.get_delta(delta)
      if cm2:
        cm2.color.r += (0.35 - cm2.color.r) * 0.15 * Global.get_delta(delta)
        cm2.color.g += (0.35 - cm2.color.g) * 0.15 * Global.get_delta(delta)
        cm2.color.b += (0.35 - cm2.color.b) * 0.15 * Global.get_delta(delta)
      env.dof_blur_near_amount += (0.35 - env.dof_blur_near_amount) * 0.35 * Global.get_delta(delta)
      
    else:
      if !why:
        for node in get_children():
          if node is Node:
            for spr in get_children():
              if spr is AnimatedSprite or spr is Sprite:
                spr.modulate.a = 1
        cm.color.r = 0.35
        cm.color.g = 0.35
        cm.color.b = 0.35
        why = true

  else:
    cm.color.r += (1 - cm.color.r) * 0.15 * Global.get_delta(delta)
    cm.color.g += (1 - cm.color.g) * 0.15 * Global.get_delta(delta)
    cm.color.b += (1 - cm.color.b) * 0.15 * Global.get_delta(delta)
    if cm2:
      cm2.color.r += (1 - cm2.color.r) * 0.15 * Global.get_delta(delta)
      cm2.color.g += (1 - cm2.color.g) * 0.15 * Global.get_delta(delta)
      cm2.color.b += (1 - cm2.color.b) * 0.15 * Global.get_delta(delta)
    env.dof_blur_near_amount += (0 - env.dof_blur_near_amount) * 0.15 * Global.get_delta(delta)

func resume() -> void:
  if get_parent().get_node_or_null('HUD'):
    for child in Global.HUD.get_children():
      if not child is AudioStreamPlayer:
        child.show()
    Global.HUD.get_node('DebugFlySprite').visible = Global.debug_fly
    Global.HUD.get_node('DebugInvisibleSprite').visible = Global.debug_inv
    Global.HUD.get_node('GameoverSprite').visible = Global.Mario.dead_gameover
  isPaused = false
  yield(get_tree().create_timer( 0.35 ), 'timeout')
  cm.modulate = Color(1, 1, 1, 1)
  if cm2: cm2.modulate = Color(1, 1, 1, 1)
  env.dof_blur_near_enabled = false
  env.dof_blur_near_amount = 0
  get_parent().popup = null
  queue_free()
  
func resetandfree() -> void:
  Global.lives = 4
  Global.score = 0
  Global.coins = 0
  Global.state = 0
  Global.projectiles_count = 0
  Global.checkpoint_active = 0
  queue_free()
