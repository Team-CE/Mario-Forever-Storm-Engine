extends CanvasLayer

var sel: int = 0
var counter: float = 1
var isPaused: bool = true
var why: bool = false

onready var env = get_parent().get_node('WorldEnvironment').environment
onready var cm = CanvasModulate.new()
var cm2

func _ready():
  cm.set_owner(self)
  cm.z_index = 99
  get_parent().add_child(cm)
  if get_parent().get_node_or_null('ParallaxBackground'):
    cm2 = CanvasModulate.new()
    get_parent().get_node('ParallaxBackground').add_child(cm2)

func _process(delta):
  if isPaused:
    get_node('sel' + str(sel)).frame = 1
    
    if cm.color.r > 0.355:
      cm.color.r += (0.35 - cm.color.r) * 0.15 * Global.get_delta(delta)
      cm.color.g += (0.35 - cm.color.g) * 0.15 * Global.get_delta(delta)
      cm.color.b += (0.35 - cm.color.b) * 0.15 * Global.get_delta(delta)
      if cm2:
        cm2.color.r += (0.35 - cm2.color.r) * 0.15 * Global.get_delta(delta)
        cm2.color.g += (0.35 - cm2.color.g) * 0.15 * Global.get_delta(delta)
        cm2.color.b += (0.35 - cm2.color.b) * 0.15 * Global.get_delta(delta)
      env.dof_blur_near_amount += (0.35 - env.dof_blur_near_amount) * 0.35 * Global.get_delta(delta)
      
      for spr in get_children():
        if spr is AnimatedSprite or spr is Sprite:
          spr.modulate.a += (1 - spr.modulate.a) * 0.1 * Global.get_delta(delta)
    else:
      counter += 0.15 * Global.get_delta(delta)
      var sinalpha = sin(counter) * 0.3 + 0.7
      get_node('sel' + str(sel)).modulate.a = sinalpha
      if !why:
        for spr in get_children():
          if spr is AnimatedSprite or spr is Sprite:
            spr.modulate.a = 1
        cm.color.r = 0.35
        cm.color.g = 0.35
        cm.color.b = 0.35
        why = true

    if Input.is_action_just_pressed('ui_down') and sel < 3:
      get_node('sel' + str(sel)).frame = 0
      get_node('sel' + str(sel)).modulate.a = 1
      sel += 1
      $choose.play()
    elif Input.is_action_just_pressed('ui_up') and sel > 0:
      get_node('sel' + str(sel)).frame = 0
      get_node('sel' + str(sel)).modulate.a = 1
      sel -= 1
      $choose.play()
    
    if Input.is_action_just_pressed('ui_accept') and counter > 1:
      match sel:
        0:
          resume()
        1:
          get_tree().change_scene(ProjectSettings.get_setting('application/config/save_game_room_scene'))
          queue_free()
        2:
          get_tree().change_scene(ProjectSettings.get_setting('application/config/main_menu_scene'))
          queue_free()
        3:
          get_tree().quit()
          queue_free()
      
      get_parent().get_tree().paused = false
      
    if Input.is_action_just_pressed('ui_cancel') and counter > 1:
      resume()
      get_parent().get_tree().paused = false
  else:
    cm.color.r += (1 - cm.color.r) * 0.15 * Global.get_delta(delta)
    cm.color.g += (1 - cm.color.g) * 0.15 * Global.get_delta(delta)
    cm.color.b += (1 - cm.color.b) * 0.15 * Global.get_delta(delta)
    if cm2:
      cm2.color.r += (1 - cm2.color.r) * 0.15 * Global.get_delta(delta)
      cm2.color.g += (1 - cm2.color.g) * 0.15 * Global.get_delta(delta)
      cm2.color.b += (1 - cm2.color.b) * 0.15 * Global.get_delta(delta)
    env.dof_blur_near_amount += (0 - env.dof_blur_near_amount) * 0.15 * Global.get_delta(delta)
    for spr in get_children():
      if spr is AnimatedSprite or spr is Sprite:
        spr.modulate.a += (0 - spr.modulate.a) * 0.15 * Global.get_delta(delta)

func resume() -> void:
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
