extends Area2D

# stiffness
var k = 0.05
# how fast the spring will stop
var d = 0.001
var spread = 0.5

var springs = []
var passes = 1

func _ready():
  var children = get_children()
  for i in children.size():
    if children[i] is Area2D:
      springs.append(children[i])
      children[i].initialize(children[i].position.x, i)
      children[i].connect('splash', self, 'splash')

func _process(delta):
  for i in springs:
    i.wave_update(k, d, delta)

  var left_deltas = []
  var right_deltas = []
  
  #initialize the values with an array of zeros
  for _i in range(springs.size()):
    left_deltas.append(0)
    right_deltas.append(0)
    
  for _j in range(passes):
    #loops through each spring of our array
    for i in range(springs.size()):
      #adds velocity to the spring to the LEFT of the current spring
      if i > 0:
        left_deltas[i] = spread * (springs[i].height - springs[i - 1].height)
        springs[i - 1].velocity += left_deltas[i] * Global.get_delta(delta)
      #adds velocity to the spring to the RIGHT of the current spring
      if i < springs.size() - 1:
        right_deltas[i] = spread * (springs[i].height - springs[i + 1].height)
        springs[i + 1].velocity += right_deltas[i] * Global.get_delta(delta)

#this function adds a speed to a spring with this index
func splash(index, speed):
  if index >= 0 and index < springs.size():
    springs[index].velocity += speed/2
    print(springs[index].velocity)


func _on_BowserLava_body_entered(body):
  
  if body.get_node_or_null('Brain') and body.get_node('Brain').has_method('lava_love'):
    body.get_node('Brain').lava_love()
