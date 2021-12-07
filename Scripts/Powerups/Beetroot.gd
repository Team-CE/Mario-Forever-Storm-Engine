class_name BeetrootAction

var fb = preload('res://Objects/Projectiles/Beetroot.tscn')

func do_action(mario):
  if Global.projectiles_count < 2:
    Global.play_base_sound('MAIN_Shoot')
    var fireball = fb.instance()
    fireball.dir = -1 if mario.get_node('Sprite').flip_h else 1
    fireball.position = Vector2(mario.position.x, mario.position.y - 32)
    Global.projectiles_count += 1
    mario.launch_counter = 2
    mario.get_parent().add_child(fireball)
