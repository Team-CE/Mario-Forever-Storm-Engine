extends Area2D


const vine = preload('res://Objects/Platforms/Vine.tscn')

var appearing: bool
var array = []

onready var firstpos = position.y

func _process(delta) -> void:
  if not appearing: return

  position.y -= 2 * Global.get_delta(delta)             # Движение
  if position.y <= firstpos - 32:                       # Создаем лозу под пираньей
    var vineindex = floor((firstpos - position.y) / 32) # Чтоб не было щелей между лозы при лагах
    if not array.has(vineindex):
      array.append(vineindex)                           # Чтоб не создавалось несколько в одной точке
      var inst = vine.instance()
      add_child(inst)                                   # Добавляем прям в нее, чтобы следовало за пираньей
      sync_anim()
      inst.position.y = vineindex * 32                  # Ставим под бонусом
    
func _physics_process(_delta) -> void:
  if not appearing: return
  if position.y >= firstpos - 32: return
  
  # Удаление
  if get_node('RayCast2D').is_colliding():
    var inst = vine.instance()
    add_child(inst)
    get_node('AnimatedSprite').queue_free()
    appearing = false
    sync_anim()

func sync_anim() -> void:
  var children = get_children()
  for i in children:
    if i is Area2D:
      i.get_node('AnimatedSprite').frame = get_node('AnimatedSprite').frame
