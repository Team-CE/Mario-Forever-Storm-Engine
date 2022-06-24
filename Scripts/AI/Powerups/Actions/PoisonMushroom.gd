func do_action(brain):
  Global._pll()
  brain.owner.get_parent().add_child(Explosion.new(brain.owner.position + Vector2(0, -16)))
  brain.owner.queue_free()
