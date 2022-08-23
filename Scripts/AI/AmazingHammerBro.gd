extends Brain

var projectile: PackedScene
var timer: float = 0

func _ready_mixin():
  owner.velocity_enabled = false
  owner.death_type = AliveObject.DEATH_TYPE.FALL

func _ai_process(delta):
  ._ai_process(delta)
  if owner.frozen:
    owner.get_node('CollisionShape2D').disabled = true
    owner.get_node('Collision2').disabled = false
    return
    
  if !owner.alive:
    owner.velocity.y += Global.gravity * 0.6 * Global.get_delta(delta)
    owner.velocity_enabled = true
    return
  
  timer += 1 * Global.get_delta(delta)
  if timer >= 25:
    timer = 0
    owner.animated_sprite.flip_h = !owner.animated_sprite.flip_h
# warning-ignore:return_value_discarded
    var proj = projectile.instance()
    proj.velocity = Vector2(-4, -1) if owner.animated_sprite.flip_h else Vector2(4, -1)
    proj.belongs = 1
    Global.current_scene.add_child(proj)
    proj.global_position = owner.global_position + (Vector2(-20, -16) if owner.animated_sprite.flip_h else Vector2(20, -16))

  if is_mario_collide('BottomDetector') and Global.Mario.velocity.y > 0:
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0, owner.sound)
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars["bounce"] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars["bounce"] * 50
  elif on_mario_collide('InsideDetector'):
    Global._ppd()
    
  var g_overlaps = owner.get_node('KillDetector').get_overlapping_bodies()
  for i in g_overlaps:
    if 'triggered' in i and i.triggered:
      owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
