extends Brain

var shoe_red = preload('res://Objects/Bonuses/ShoeRed.tscn')
var shoe_created: bool = false
var ooawel: bool = false
var death_bool: bool = false

func _ai_process(delta:float) -> void:
  ._ai_process(delta)
  if !owner.is_on_floor():
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
  
  if !owner.alive:
    if not death_bool:
      death_bool = true
      var shoe = shoe_red.instance()
      Global.current_scene.add_child(shoe)
      shoe.global_transform = owner.global_transform
      shoe.position.y += 4 * Global.get_delta(delta)
      shoe.get_node('AnimatedSprite').flip_h = min(owner.dir, 0)
      if shoe_created: return
      shoe.dead = true
      shoe.get_node('AnimatedSprite').flip_v = true
      
    return
    
  owner.get_node('AnimatedSprite2').flip_h = min(owner.dir, 0)
  
  owner.velocity.x = owner.vars['speed'] * owner.dir * int(not owner.is_on_floor())
  if owner.is_on_wall():
    owner.turn()
  
  if owner.is_on_floor() and not ooawel:
    owner.get_node('AnimationPlayer').play('hi')
    ooawel = true
    
  if owner.temp:
    jump()
    ooawel = false
    owner.temp = false

  if is_mario_collide('BottomDetector'):
    owner.kill(AliveObject.DEATH_TYPE.FALL, 0)
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
      shoe_created = true
      
  owner.animated_sprite.flip_h = false

func jump():
  owner.dir = 1 if Global.Mario.position.x > owner.position.x else -1
  owner.velocity.y = -400
  ooawel = false

func _on_any_death():
  owner.get_node('AnimatedSprite2').queue_free()
