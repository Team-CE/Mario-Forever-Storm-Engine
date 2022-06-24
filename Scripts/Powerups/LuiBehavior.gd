func _process_mixin(powerup, delta) -> void:
  if powerup.owner.is_on_floor() and !powerup.appearing:
    powerup.owner.gravity_scale = 0.5
    powerup.owner.velocity.y = -400
    powerup.owner.sound.play()
