extends Label

export var free_on_end: bool = true

func _ready():
	var tw: SceneTreeTween = create_tween()
# warning-ignore:return_value_discarded
	tw.connect('loop_finished', self, '_on_loop_finished')
# warning-ignore:return_value_discarded
	tw.tween_property(self, 'rect_position:y', 200.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
# warning-ignore:return_value_discarded
	tw.tween_property(self, 'rect_position:y', 520.0, 1.0).set_ease(Tween.EASE_IN).set_delay(2.5).set_trans(Tween.TRANS_CUBIC)

func _on_loop_finished():
	if free_on_end:
		queue_free()
