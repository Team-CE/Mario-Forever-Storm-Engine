tool
extends Control

export var text: String = 'MUSIC NAME' setget _set_text
export var size: int = 35 setget _set_size

func _ready():
	$Label.text = text
	$Label.rect_position = Vector2(0, 496)

func _set_text(new) -> void:
	$Label.text = new
	text = new
	pass

func _set_size(new) -> void:
	var font: DynamicFont = preload('res://GFX/Fonts/LoliPop.tres').duplicate()
	font.size = new
	size = new
	$Label.set('custom_fonts/font', font)
