extends Area2D

var lastBody : Node2D

func _process(delta):
	var newPos = get_global_mouse_position()
	set_position(newPos)
	newPos.y += 10
	newPos.x += 10
	$InspectLabel.set_position(newPos - position)
	if lastBody != null:
		$InspectLabel.text = lastBody.getInfo()


func _input(event : InputEvent):
	if event is InputEventMouseButton:
		var ev :InputEventMouseButton = event
		if ev.pressed:
			if ev.get_button_index() == 1:
				$InspectLabel.visible = !$InspectLabel.visible


func _on_Inspector_body_entered(body:Node2D):
	if body.has_method("getInfo"):
		lastBody = body
