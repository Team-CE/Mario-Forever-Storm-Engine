var fb = preload('res://Objects/Projectiles/Iceball.tscn')

func do_action(mario):
  if Global.projectiles_count < 2:
    Global.play_base_sound('MAIN_Shoot')
    var fireball = fb.instance()
    fireball.dir = -1 if mario.get_node('Sprite').flip_h else 1
    fireball.rotation = mario.rotation
    fireball.position = mario.position + Vector2(0, -32).rotated(fireball.rotation)
    Global.projectiles_count += 1
    mario.launch_counter = 2
    mario.get_parent().add_child(fireball)
