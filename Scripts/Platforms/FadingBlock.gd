tool
extends StaticBody2D

export var sprite: Texture = preload('res://GFX/Tilesets/CBlock.png')
export var speed: float = 2
export var offset: int = 0

var counter: float = 0

func _ready() -> void:
  counter = offset

func _process(delta: float) -> void:
  if $Sprite.texture != sprite:
    $Sprite.texture = sprite
  if !Engine.editor_hint:
    counter += speed * Global.get_delta(delta)
    if counter < 500:
      $Collision.disabled = false
      if $Sprite.modulate.a < 1:
        $Sprite.modulate.a += 0.1 * Global.get_delta(delta)
    elif counter < 1000:
      $Collision.disabled = true
      if $Sprite.modulate.a > 0:
        $Sprite.modulate.a -= 0.1 * Global.get_delta(delta)
    else:
      counter = 0
  $LightOccluder2D.visible = $Sprite.modulate.a > 0.5
