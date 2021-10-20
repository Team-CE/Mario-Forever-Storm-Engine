class_name LuiAction

var trail_counter: float = 0

func _process_mixin(mario, delta):
  if mario.velocity.y < 550 and not mario.is_on_floor():
    if Input.is_action_pressed('mario_jump') and not Input.is_action_pressed('mario_crouch') and mario.velocity.y < 0:
      mario.velocity.y -= 5 * Global.get_delta(delta)

  trail_counter += 1 * Global.get_delta(delta)
  
  if trail_counter > 2 and mario.get_node('Sprite').animation == 'Jumping':
    mario.get_parent().add_child(LuiTrail.new(mario.position - Vector2(0, 28), mario.get_node('Sprite').flip_h))
    trail_counter = 0
