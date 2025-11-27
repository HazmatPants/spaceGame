extends Area3D

var atm: float = 1.0
var o2: float = 1.0

func _ready() -> void:
	add_to_group(&"hull")
