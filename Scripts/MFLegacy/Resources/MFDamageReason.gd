class_name MFDamageReason extends Resource

enum Damage{
	Simple
}

var from
export var damage: int
export(Damage) var type: int
export var element: Resource

func _init(from: MFEntity):
	self.from = from

