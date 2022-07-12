extends Node2D

func _ready():
  $Mario.controls_enabled = false
  $Mario.get_node('Camera').limit_right = 640
  yield(get_tree(), 'idle_frame')
  $Mario.velocity.x = 450

func _process(_delta):
  if $Mario.velocity.x < 75 && $Mario.velocity.x > 1:
    $Mario.velocity.x = 75
  if $Mario.get_node('InsideDetector').get_overlapping_areas().has($Warp) and not $Warp.active:
    $letspipe.play()
    $Warp.calc_pos = Vector2($Warp.position.x - 16, $Warp.position.y + 16)
    $Warp.active = true
    $Mario.animate_sprite('Walking')
    $Mario/Sprite.speed_scale = 5
    $Mario/Sprite.flip_h = false
    $Warp.warp_dir = Vector2(1, 0)
  if $Warp.counter > 36:
    $Mario/Sprite.visible = false
