extends Area2D


const vine = preload('res://Objects/Platforms/Vine.tscn')

var appearing: bool
var array = []

onready var firstpos = position.rotated(-rotation).y

func _process(delta) -> void:
	if not appearing: return

	position -= Vector2(0, 2).rotated(rotation) * Global.get_delta(delta)						 # Head Movement
	
	var normal_pos = position.rotated(-rotation)
	if normal_pos.y <= firstpos - 32:											 # Creating vine under piranha head
		var vineindex: float = floor((firstpos - normal_pos.y) / 32) # To avoid holes between vines on lag
		if not array.has(vineindex):
			array.append(vineindex)													 # To avoid multiple in one point
			var inst = vine.instance()
			add_child(inst)																	 # Adding right into the head so it follows
			sync_anim()
			inst.position = Vector2(0, vineindex * 32).rotated(inst.rotation)									# Creating under bonus block

func _physics_process(_delta) -> void:
	if not appearing: return
	if position.rotated(-rotation).y >= firstpos - 32: return
	
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
