extends Area2D


const vine = preload('res://Objects/Platforms/Vine.tscn')

var appearing: bool
var array = []

onready var firstpos = position.y

func _process(delta) -> void:
  if not appearing: return

  position.y -= 2 * Global.get_delta(delta)             # Movement
  if position.y <= firstpos - 32:                       # Creating vine under piranha head
    var vineindex = floor((firstpos - position.y) / 32) # To avoid holes between vines on lag
    if not array.has(vineindex):
      array.append(vineindex)                           # To avoid multiple in one point
      var inst = vine.instance()
      add_child(inst)                                   # Adding right into the head so it follows
      sync_anim()
      inst.position.y = vineindex * 32                  # Creating under bonus block
    
func _physics_process(_delta) -> void:
  if not appearing: return
  if position.y >= firstpos - 32: return
  
  # Deletion
  if $RayCast2D.is_colliding() and ($RayCast2D.get_collider() is TileMap or $RayCast2D.get_collider().is_in_group('Solid')):
    var inst = vine.instance()
    add_child(inst)
    $AnimatedSprite.queue_free()
    appearing = false
    array = []
    sync_anim()

func sync_anim() -> void:
  var children = get_children()
  for i in children:
    if i is Area2D:
      i.get_node('AnimatedSprite').frame = $AnimatedSprite.frame
