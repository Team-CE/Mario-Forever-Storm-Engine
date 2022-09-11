extends Area2D

var lastBody : Node2D

func _ready() -> void:
	$InspectLabel.visible = false

func _process(_delta) -> void:
	var newPos = get_global_mouse_position()
	set_position(newPos)
#	newPos.y += 10
#	newPos.x += 10
	$InspectLabel.set_position(newPos - position)
	if is_instance_valid(lastBody):
		$InspectLabel.text = lastBody.getInfo()
	else:
		$InspectLabel.text = 'null'


func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.pressed and ev.get_button_index() == 2: # Right mouse button
			$InspectLabel.visible = !$InspectLabel.visible


func _on_Inspector_body_entered(body: Node2D) -> void:
	if body.has_method('getInfo'):
		lastBody = body
