class_name MFEntity extends KinematicBody2D

signal player_touch(PD)
signal drop()
signal kill()

var invincible: bool
var affect_by_graity: bool
var frosable: bool
var alive: bool
var frosed: bool
var can_be_dropped: bool

func _kill() -> void:
	# Place Holder
	queue_free()
