tool
extends Control

export var text: String = 'MUSIC NAME' setget _set_text
export var size: int = 35 setget _set_size

func _ready():
	$Label.text = text
	$Label.rect_position = Vector2(0, 496)
	if !Engine.editor_hint:
		visible = Global.overlay
		if 'overlay' in Global.current_scene:
			Global.current_scene.overlay = self
			if !Global.current_scene.is_connected('overlay_changed', self, '_on_overlay_toggled'):
				Global.current_scene.connect('overlay_changed', self, '_on_overlay_toggled')

func _set_text(new) -> void:
	$Label.text = new
	text = new
	pass

func _set_size(new) -> void:
	var font: DynamicFont = preload('res://GFX/Fonts/LoliPop.tres').duplicate()
	font.size = new
	size = new
	$Label.set('custom_fonts/font', font)

func display_text(string: String):
	if !Global.overlay:
		return
	$Label.text = string
	$AnimationPlayer.seek(0)
	$AnimationPlayer.play()

func _on_overlay_toggled():
	if visible != Global.overlay:
		visible = Global.overlay
