extends CanvasLayer

var isPaused: bool = true
var why: bool = false
var options: bool = false

onready var env = $Sprite.material

export var darkness: float = 0.35
export var speed: float = 0.15

func _ready():
  if Global.HUD:
    for child in Global.HUD.get_children():
      if not child is AudioStreamPlayer:
        child.hide()
  if !Global.effects or Global.quality == 0:
    env = null

func _process(delta):
  if isPaused:
    if $Sprite.modulate.v > 0.355:
      $Sprite.modulate.v += (darkness - $Sprite.modulate.v) * speed * Global.get_delta(delta)
      if env: env.set_shader_param('amount', env.get_shader_param('amount') + (darkness - env.get_shader_param('amount')) * darkness * Global.get_delta(delta))
      
    else:
      if !why:
        for node in get_children():
          if node.get_class() == 'Node2D':
            node.modulate.a = 1
        $Sprite.modulate.v = darkness
        why = true

  else:
    $Sprite.modulate.v += (1 - $Sprite.modulate.v) * speed * Global.get_delta(delta)
    if env: env.set_shader_param('amount', env.get_shader_param('amount') + (0 - env.get_shader_param('amount')) * speed * Global.get_delta(delta))

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
  Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
  
  yield(get_tree().create_timer( darkness, false), 'timeout')
  
  $Sprite.modulate = Color.white
  
  if get_tree().get_current_scene().get_class() == 'Level': get_parent().popup = null
  queue_free()
