extends Node2D

export var projectile: PackedScene = preload('res://Objects/Projectiles/Hammer.tscn')
export var include_bro: bool = true

func _ready():
	if !include_bro:
		$'%AmazingBro'.queue_free()
	else:
		$'%AmazingBro/Brain'.projectile = projectile
